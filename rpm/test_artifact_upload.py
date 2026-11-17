import base64
import contextlib
import http.client
from http.server import BaseHTTPRequestHandler, HTTPServer
import io
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest import mock
from urllib.parse import quote

import artifact_upload as upload


DESTINATION = 'https://engci-maven.cisco.com/artifactory/noiro-snapshot/release/wallaby/fixture'
USERNAME = 'fixture-user'
TOKEN = 'fixture-private-token-never-log'


class FixtureHandler(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def log_message(self, unused_format, *unused_arguments):
        pass

    def do_PUT(self):
        length = int(self.headers['Content-Length'])
        content = self.rfile.read(length)
        self.server.requests.append({'path': self.path, 'length': length, 'content': content,
                                     'authorization': self.headers.get('Authorization'),
                                     'transfer_encoding': self.headers.get('Transfer-Encoding')})
        status = self.server.statuses.pop(0)
        body = ('private-response-password=' + TOKEN).encode('ascii')
        self.send_response(status)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Connection', 'close')
        if 300 <= status < 400:
            self.send_header('Location', 'https://unapproved.invalid/private/' + TOKEN)
        self.end_headers()
        self.wfile.write(body)


class TrackedConnection(http.client.HTTPConnection):
    def __init__(self, fixture, requested_host, port, timeout):
        fixture.factory_calls.append((requested_host, port, timeout))
        http.client.HTTPConnection.__init__(self, '127.0.0.1', fixture.server.server_port, timeout=timeout)
        self.was_closed = False
        fixture.connections.append(self)

    def close(self):
        self.was_closed = True
        http.client.HTTPConnection.close(self)


class UploadFixture(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.server = HTTPServer(('127.0.0.1', 0), FixtureHandler)
        self.server.requests, self.server.statuses = [], []
        self.factory_calls, self.connections = [], []
        self.thread = threading.Thread(target=self.server.serve_forever)
        self.thread.daemon = True
        self.thread.start()
        self.factory = lambda host, port, timeout: TrackedConnection(self, host, port, timeout)

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)
        self.temporary.cleanup()

    def artifact(self, name='fixture.rpm', content=b'fixture artifact\n'):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        return path

    def publish(self, paths, destination=DESTINATION):
        return upload.publish_files(destination, paths, USERNAME, TOKEN, self.factory)

    def test_success_statuses_stream_exact_bytes_and_quote_filename(self):
        self.server.statuses = [200, 201, 204]
        names = ['first.rpm', 'package "quoted" #+?.tar.gz', 'last.sig']
        contents = [b'A' * (1024 * 1024 + 19), b'second artifact\x00\xff', b'detached signature']
        paths = [self.artifact(name, content) for name, content in zip(names, contents)]
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            self.assertEqual(self.publish(paths, DESTINATION + '/'), names)
        self.assertEqual(stdout.getvalue() + stderr.getvalue(), '')
        self.assertEqual(len(self.server.requests), 3)
        for request, name, content in zip(self.server.requests, names, contents):
            self.assertEqual(request['path'], '/artifactory/noiro-snapshot/release/wallaby/fixture/' + quote(name, safe=''))
            self.assertEqual(request['content'], content)
            self.assertEqual(request['length'], len(content))
            self.assertIsNone(request['transfer_encoding'])
            self.assertEqual(request['authorization'], 'Basic ' + base64.b64encode((USERNAME + ':' + TOKEN).encode()).decode())
        self.assertTrue(all(item == (upload.HOST, 443, 60) for item in self.factory_calls))
        self.assertTrue(all(connection.was_closed for connection in self.connections))

    def test_rejected_http_status_stops_before_next_put_and_never_logs_response(self):
        first, second = self.artifact('first.rpm'), self.artifact('second.rpm')
        for status in (301, 302, 307, 308, 401, 403, 500, 503):
            with self.subTest(status=status):
                self.server.requests[:] = []
                self.server.statuses = [status, 201]
                stdout, stderr = io.StringIO(), io.StringIO()
                with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                    with self.assertRaises(upload.UploadError) as error:
                        self.publish([first, second])
                self.assertEqual(str(error.exception), 'Artifact upload rejected (HTTP {}).'.format(status))
                self.assertEqual(error.exception.http_status, status)
                self.assertEqual(len(self.server.requests), 1)
                self.assertEqual(stdout.getvalue() + stderr.getvalue(), '')
                self.assertNotIn(TOKEN, str(error.exception))
                self.assertTrue(self.connections[-1].was_closed)

    def test_first_success_then_failure_does_not_send_third_file(self):
        paths = [self.artifact(name) for name in ('first.rpm', 'second.rpm', 'third.rpm')]
        self.server.statuses = [201, 403, 201]
        with self.assertRaises(upload.UploadError):
            self.publish(paths)
        self.assertEqual([item['path'].rsplit('/', 1)[1] for item in self.server.requests], ['first.rpm', 'second.rpm'])
        self.assertTrue(all(connection.was_closed for connection in self.connections))

    def test_all_files_are_checked_before_any_network_request(self):
        first = self.artifact()
        empty = self.artifact('empty.rpm', b'')
        directory = self.root / 'directory.rpm'
        directory.mkdir()
        symlink = self.root / 'symlink.rpm'
        symlink.symlink_to(first)
        fifo = self.root / 'pipe.rpm'
        os.mkfifo(str(fifo))
        for invalid in (self.root / 'missing.rpm', self.root / '*.rpm', empty, directory, symlink, fifo):
            with self.subTest(kind=invalid.name):
                with self.assertRaises(upload.UploadError):
                    self.publish([first, invalid])
        self.assertEqual(self.factory_calls, [])
        self.assertEqual(self.server.requests, [])

    def test_duplicate_basenames_and_empty_input_fail_before_connection(self):
        first = self.artifact('one/duplicate.rpm')
        second = self.artifact('two/duplicate.rpm')
        for paths in ([], [first, second], [first, first]):
            with self.assertRaises(upload.UploadError):
                self.publish(paths)
        self.assertEqual(self.factory_calls, [])

    def test_destination_restrictions_cannot_be_bypassed_by_injected_factory(self):
        path = self.artifact()
        destinations = [
            'http://engci-maven.cisco.com/artifactory/noiro-snapshot/release/',
            'https://127.0.0.1/artifactory/noiro-snapshot/release/',
            'https://engci-maven.cisco.com:8443/artifactory/noiro-snapshot/release/',
            'https://user:password@engci-maven.cisco.com/artifactory/noiro-snapshot/release/',
            'https://engci-maven.cisco.com/artifactory/another-repository/release/',
            DESTINATION + '?token=private', DESTINATION + '#fragment', DESTINATION + '?', DESTINATION + '#',
            DESTINATION + '/../outside', DESTINATION + '/%2e%2e/outside',
            DESTINATION + '/%2e%2e%2foutside', DESTINATION + '/%252e%252e/outside',
            DESTINATION + '/\\outside', DESTINATION + '/%00outside',
            'https://engci-maven.cisco.com\n/artifactory/noiro-snapshot/release/',
        ]
        for destination in destinations:
            with self.subTest(destination=destination):
                with self.assertRaises(upload.UploadError):
                    self.publish([path], destination)
        self.assertEqual(self.factory_calls, [])

    def test_network_failure_closes_connection_and_hides_exception_body(self):
        path = self.artifact()
        class BrokenConnection:
            closed = False
            def request(self, *arguments, **keywords):
                raise OSError('private connection failure ' + TOKEN)
            def close(self):
                self.closed = True
        connection = BrokenConnection()
        with self.assertRaises(upload.UploadError) as error:
            upload.publish_files(DESTINATION, [path], USERNAME, TOKEN, lambda *args, **kwargs: connection)
        self.assertEqual(str(error.exception), 'Artifact upload failed (OSError).')
        self.assertIsNone(error.exception.http_status)
        self.assertTrue(connection.closed)
        self.assertNotIn(TOKEN, str(error.exception))

    def test_real_socket_disconnect_is_a_failure_without_uploading_second_file(self):
        path = self.artifact()
        self.server.statuses = [201]
        connection = http.client.HTTPConnection('127.0.0.1', self.server.server_port, timeout=2)
        connection.connect()
        connection.sock.shutdown(socket.SHUT_RDWR)
        with self.assertRaises(upload.UploadError):
            upload.publish_files(DESTINATION, [path, self.artifact('second.rpm')], USERNAME, TOKEN,
                                 lambda *args, **kwargs: connection)
        self.assertEqual(self.server.requests, [])
        self.assertIsNone(connection.sock)

    def test_cli_credentials_stay_in_environment_and_errors_stay_quiet(self):
        path = self.artifact()
        command = [sys.executable, '-B', str(Path(upload.__file__)), DESTINATION, str(path), str(self.root / 'missing.rpm')]
        environment = dict(os.environ, ARTIFACTORY_USER=USERNAME, ARTIFACT_TOKEN=TOKEN)
        result = subprocess.run(command, env=environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                universal_newlines=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertIn('Artifact validation failed (FileNotFoundError).', result.stderr)
        for private in (USERNAME, TOKEN, base64.b64encode((USERNAME + ':' + TOKEN).encode()).decode()):
            self.assertNotIn(private, result.stdout + result.stderr + ' '.join(command))
        self.assertEqual(self.server.requests, [])
        rejected = subprocess.run([sys.executable, '-B', str(Path(upload.__file__)),
                                   'http://127.0.0.1:{}/artifactory/noiro-snapshot/release'.format(self.server.server_port), str(path)],
                                  env=environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.assertNotEqual(rejected.returncode, 0)
        self.assertEqual(self.server.requests, [])

    def test_missing_credentials_fail_before_network(self):
        path = self.artifact()
        for username, token in (('', TOKEN), (USERNAME, ''), (None, TOKEN), (USERNAME, None), ('user:password', TOKEN)):
            with self.assertRaises(upload.UploadError):
                upload.publish_files(DESTINATION, [path], username, token, self.factory)
        self.assertEqual(self.factory_calls, [])


if __name__ == '__main__':
    unittest.main()
