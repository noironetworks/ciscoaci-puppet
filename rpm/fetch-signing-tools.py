#!/usr/bin/env python3
"""Install the pinned SWIMS signing client without exposing download credentials."""

import base64
import hashlib
import os
from pathlib import Path, PurePosixPath
import sys
import tarfile
import tempfile
import urllib.request


ARCHIVE = "rpm_deb_signing.fy26_dist01.tar.gz"
ARCHIVE_ROOT = "rpm_deb_signing.fy26_dist01"
URL = (
    "https://artifactory.devhub-cloud.cisco.com/artifactory/"
    "STO_Image_Signing_Clients-devhub-generic-local/rpm_deb_sign/" + ARCHIVE
)
SHA256 = "a296567d5ad942e1cc9fefe01b6350f5f32e15ee3e98dd4d64b0d25d5b676414"
TOOLS = "Linux-64/swims-openpgp"
REQUIRED = ("code_sign.8.x86_64", "rpm_sign_batchmode.py3", "run-extsign", "run-make-cert.exp")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward the Artifactory credential to a redirected destination.
        return None


def install(destination):
    username = os.environ["RPM_DEB_SIGN_ARTIFACTORY_USER"]
    token = os.environ["RPM_DEB_SIGN_ARTIFACTORY_TOKEN"]
    if not username or not token:
        raise ValueError("Missing signing-client download credentials")
    auth = base64.b64encode((username + ":" + token).encode()).decode()
    request = urllib.request.Request(URL, headers={"Authorization": "Basic " + auth})
    destination = Path(destination).absolute()
    if destination.name != "rpm_deb_signing" or destination.is_symlink():
        raise ValueError("Destination must be a non-symlink rpm_deb_signing directory")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".signing-client-", dir=str(destination.parent)) as temporary:
        temporary = Path(temporary)
        archive = temporary / ARCHIVE
        digest = hashlib.sha256()
        opener = urllib.request.build_opener(NoRedirect())
        with opener.open(request, timeout=60) as response, archive.open("wb") as output:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                output.write(chunk)
                digest.update(chunk)
        if digest.hexdigest() != SHA256:
            raise ValueError("Signing-client archive SHA-256 mismatch")
        with tarfile.open(str(archive), "r:gz") as package:
            for member in package.getmembers():
                path = PurePosixPath(member.name)
                if (path.is_absolute() or ".." in path.parts or not path.parts
                        or path.parts[0] != ARCHIVE_ROOT
                        or not (member.isdir() or member.isfile())):
                    raise ValueError("Unexpected signing-client archive layout")
            package.extractall(str(temporary))
        extracted = temporary / ARCHIVE_ROOT
        for name in REQUIRED:
            if not (extracted / TOOLS / name).is_file():
                raise ValueError("Signing-client archive is missing a required tool")
        for name in ("code_sign.8.x86_64", "run-extsign", "run-make-cert.exp"):
            if not os.access(str(extracted / TOOLS / name), os.X_OK):
                raise ValueError("Signing-client archive has a non-executable tool")
        previous = temporary / "previous"
        if destination.exists():
            destination.rename(previous)
        try:
            extracted.rename(destination)
        except OSError:
            if previous.exists():
                previous.rename(destination)
            raise
    print("Installed {} (SHA-256 {})".format(ARCHIVE, SHA256))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: fetch-signing-tools.py <destination>/rpm_deb_signing")
    try:
        install(sys.argv[1])
    except Exception as error:
        # Exception bodies and HTTP response bodies can contain authentication data.
        sys.exit("Signing-client installation failed ({})".format(type(error).__name__))
