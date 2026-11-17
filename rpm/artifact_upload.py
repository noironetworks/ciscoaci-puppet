#!/usr/bin/env python3
"""Publish artifacts to EngCI without credential-bearing argv or HTTP logs."""

import base64
from contextlib import ExitStack
import http.client
import os
from pathlib import Path
import stat
import sys
from urllib.parse import quote, unquote, urlsplit


HOST = 'engci-maven.cisco.com'
PORT = 443
REPOSITORY_PREFIX = '/artifactory/noiro-snapshot/'


class UploadError(Exception):
    """An upload failed; messages contain fixed text, status, or class only."""

    def __init__(self, message, http_status=None):
        Exception.__init__(self, message)
        self.http_status = http_status


def destination_prefix(destination):
    """Validate the fixed HTTPS repository and return a canonical URL path."""
    try:
        if (not isinstance(destination, str) or any(ord(char) < 33 or ord(char) == 127 for char in destination)
                or '?' in destination or '#' in destination):
            raise ValueError()
        parsed = urlsplit(destination)
        if (parsed.scheme != 'https' or parsed.hostname != HOST or parsed.port not in (None, PORT)
                or parsed.username is not None or parsed.password is not None
                or parsed.query or parsed.fragment or not parsed.path.startswith(REPOSITORY_PREFIX)):
            raise ValueError()
        path = unquote(parsed.path, errors='strict')
        components = path.rstrip('/').split('/')[1:]
        if (not path.startswith(REPOSITORY_PREFIX) or '%' in path or '\\' in path
                or any(ord(char) < 32 or ord(char) == 127 for char in path)
                or any(part in ('', '.', '..') for part in components)):
            raise ValueError()
        return quote(path.rstrip('/'), safe='/-._~') + '/'
    except (TypeError, ValueError):
        raise UploadError('Destination must be the approved EngCI HTTPS repository without URL credentials or traversal.') from None


def open_artifacts(paths, stack):
    """Open and validate every artifact before any network connection exists."""
    artifacts, names = [], set()
    for value in paths:
        try:
            path = Path(value)
            name = path.name
            if name in names:
                raise UploadError('Artifact basenames must be unique.')
            metadata = path.lstat()
            if not stat.S_ISREG(metadata.st_mode) or metadata.st_size <= 0:
                raise UploadError('Every artifact must be a nonempty regular file, without symlinks.')
            flags = os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0) | getattr(os, 'O_NONBLOCK', 0)
            descriptor = os.open(str(path), flags)
            stream = stack.enter_context(os.fdopen(descriptor, 'rb'))
            opened = os.fstat(stream.fileno())
            if (not stat.S_ISREG(opened.st_mode) or opened.st_size <= 0
                    or (metadata.st_dev, metadata.st_ino) != (opened.st_dev, opened.st_ino)):
                raise UploadError('An artifact changed during local validation.')
        except UploadError:
            raise
        except (OSError, TypeError, ValueError) as error:
            raise UploadError('Artifact validation failed ({}).'.format(type(error).__name__)) from None
        names.add(name)
        artifacts.append((name, stream, opened.st_size))
    if not artifacts:
        raise UploadError('At least one artifact is required.')
    return artifacts


def publish_files(destination, paths, username, token, connection_factory=None):
    """PUT all validated files; an injected connection factory is for fixtures.

    The production CLI always uses HTTPSConnection to the fixed EngCI host.
    Neither this function nor its errors print credentials or response bodies.
    """
    prefix = destination_prefix(destination)
    if (not isinstance(username, str) or not isinstance(token, str) or not username or not token
            or ':' in username or any(char in username + token for char in ('\r', '\n', '\x00'))):
        raise UploadError('Publication credentials are missing or unsupported.')
    authorization = 'Basic ' + base64.b64encode((username + ':' + token).encode('utf-8')).decode('ascii')
    factory = connection_factory or http.client.HTTPSConnection
    uploaded = []
    with ExitStack() as stack:
        artifacts = open_artifacts(paths, stack)
        for name, stream, size in artifacts:
            connection = None
            response = None
            try:
                connection = factory(HOST, port=PORT, timeout=60)
                connection.request('PUT', prefix + quote(name, safe=''), body=stream, headers={
                    'Authorization': authorization,
                    'Content-Length': str(size),
                    'Content-Type': 'application/octet-stream',
                })
                response = connection.getresponse()
                if not 200 <= response.status < 300:
                    raise UploadError('Artifact upload rejected (HTTP {}).'.format(response.status),
                                      http_status=response.status)
                uploaded.append(name)
            except UploadError:
                raise
            except Exception as error:
                raise UploadError('Artifact upload failed ({}).'.format(type(error).__name__)) from None
            finally:
                for resource in (response, connection):
                    if resource is not None:
                        try:
                            resource.close()
                        except Exception:
                            # A close error must not leak response data or prevent
                            # the remaining connection cleanup attempt.
                            pass
    return uploaded


def main(arguments=None):
    arguments = sys.argv[1:] if arguments is None else arguments
    if len(arguments) < 2:
        raise UploadError('Usage: artifact_upload.py DESTINATION FILE [FILE ...]')
    uploaded = publish_files(arguments[0], arguments[1:], os.environ.get('ARTIFACTORY_USER'),
                             os.environ.get('ARTIFACT_TOKEN'))
    print('Published {} artifact(s).'.format(len(uploaded)))
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except UploadError as error:
        sys.exit('Artifact publication failed: ' + str(error))
    except Exception as error:
        sys.exit('Artifact publication failed ({}).'.format(type(error).__name__))
