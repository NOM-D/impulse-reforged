"""Upload tracked runtime files through Wings SFTP; never execute remote commands."""

import base64
import errno
import hashlib
import hmac
import os
from pathlib import Path, PurePosixPath
import stat
import subprocess

import paramiko

HOST = "nicely-das.tun.ply.gg"
PORT = 11986
DESTINATION = PurePosixPath("/garrysmod/gamemodes/impulse-reforged")
RUNTIME_DIRS = {"content", "entities", "gamemode", "plugins"}
RUNTIME_FILES = {"impulse-reforged.txt", "version.txt", "LICENSE"}


def runtime_paths():
    tracked = subprocess.check_output(["git", "ls-files", "-z"]).decode().split("\0")
    paths = []
    for name in filter(None, tracked):
        path = PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts:
            raise RuntimeError("Unsafe source path")
        if path.parts[0] not in RUNTIME_DIRS and name not in RUNTIME_FILES:
            continue
        local = Path(name)
        if any(part.is_symlink() for part in [local, *local.parents]):
            raise RuntimeError("Symlinks cannot be deployed")
        if not local.is_file():
            raise RuntimeError("A tracked runtime file is missing")
        paths.append(path)
    if PurePosixPath("impulse-reforged.txt") not in paths or not any(
        p.parts[0] == "gamemode" for p in paths
    ):
        raise RuntimeError("Expected gamemode files were not found")
    return sorted(paths)


class VerifyFingerprint(paramiko.MissingHostKeyPolicy):
    def __init__(self, expected):
        self.expected = expected

    def missing_host_key(self, client, hostname, key):
        digest = base64.b64encode(hashlib.sha256(key.asbytes()).digest()).decode().rstrip("=")
        if not hmac.compare_digest("SHA256:" + digest, self.expected):
            raise paramiko.SSHException("SFTP host key mismatch; deployment refused")


def ensure_directory(sftp, path, create=False):
    try:
        attributes = sftp.lstat(str(path))
    except OSError as exc:
        if exc.errno != errno.ENOENT or not create:
            raise
        sftp.mkdir(str(path))
        attributes = sftp.lstat(str(path))
    if not stat.S_ISDIR(attributes.st_mode):
        raise RuntimeError("Destination directory is not a real directory")


def upload(sftp, paths):
    ensure_directory(sftp, "/garrysmod")
    ensure_directory(sftp, "/garrysmod/gamemodes")
    ensure_directory(sftp, DESTINATION, create=True)
    checked = {DESTINATION}
    for path in paths:
        remote = DESTINATION / path
        for parent in reversed(remote.parents):
            if parent == DESTINATION or DESTINATION in parent.parents:
                if parent not in checked:
                    ensure_directory(sftp, parent, create=True)
                    checked.add(parent)
        try:
            attributes = sftp.lstat(str(remote))
        except OSError as exc:
            if exc.errno != errno.ENOENT:
                raise
        else:
            if not stat.S_ISREG(attributes.st_mode):
                raise RuntimeError("Refusing to overwrite a non-regular file")
        sftp.put(str(path), str(remote), confirm=True)
    print(f"Uploaded {len(paths)} runtime files to {DESTINATION}.")
    print("No remote files were deleted. Server power state was not changed.")


def main():
    required = ("SFTP_USERNAME", "SFTP_PASSWORD", "SFTP_HOST_KEY_SHA256")
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError("Missing GitHub Secrets: " + ", ".join(missing))
    fingerprint = os.environ["SFTP_HOST_KEY_SHA256"].strip()
    if not fingerprint.startswith("SHA256:") or len(fingerprint) != 50:
        raise RuntimeError("SFTP_HOST_KEY_SHA256 must contain only SHA256: plus the fingerprint")
    paths = runtime_paths()
    with paramiko.SSHClient() as client:
        client.set_missing_host_key_policy(VerifyFingerprint(fingerprint))
        client.connect(
            HOST, port=PORT, username=os.environ["SFTP_USERNAME"],
            password=os.environ["SFTP_PASSWORD"], look_for_keys=False,
            allow_agent=False, timeout=30, banner_timeout=30, auth_timeout=30,
        )
        client.get_transport().set_keepalive(30)
        with client.open_sftp() as sftp:
            sftp.get_channel().settimeout(120)
            upload(sftp, paths)


if __name__ == "__main__":
    main()
