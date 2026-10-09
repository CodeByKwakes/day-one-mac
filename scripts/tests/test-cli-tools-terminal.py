#!/usr/bin/env python3
"""Check category selection on a real terminal with a private Homebrew fixture."""

import errno
import os
from pathlib import Path
import pty
import select
import signal
import subprocess
import tempfile
import time


SCRIPT = Path(__file__).resolve().parents[1] / "configure-cli-tools.sh"


def exercise(env, keys, expected, status=0):
    pid, master = pty.fork()
    if pid == 0:
        os.execve("/bin/bash", ["/bin/bash", str(SCRIPT), "--dry-run"], env)
    output = bytearray()
    sent = False
    finished = False
    try:
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if not select.select([master], [], [], 0.1)[0]:
                continue
            try:
                chunk = os.read(master, 65536)
            except OSError as exc:
                if exc.errno == errno.EIO:
                    break
                raise
            if not chunk:
                break
            output.extend(chunk)
            if not sent and b"Directory jumper learned from shell history" in output:
                first = output.decode()
                assert "Navigation (5/7)" in first
                assert "lazydocker" not in first and "shellcheck" not in first
                assert first.count("\n") < 25, first
                os.write(master, keys)
                sent = True
        else:
            raise AssertionError("CLI selector timed out")
        _, result = os.waitpid(pid, 0)
        finished = True
        text = output.decode()
        assert os.waitstatus_to_exitcode(result) == status, text
        assert expected in text, text
        return text
    finally:
        if not finished:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
        os.close(master)


with tempfile.TemporaryDirectory(prefix="day-one-cli-", dir="/private/tmp") as root:
    home = Path(root) / "home with spaces"
    binary = home / "bin"
    binary.mkdir(parents=True)
    brew = binary / "brew"
    brew.write_text('#!/bin/sh\n[ "$1:$2" = list:--formula ] || exit 97\nprintf "eza\\n"\n')
    brew.chmod(0o700)
    env = dict(os.environ, HOME=str(home), PATH=f"{binary}:/usr/bin:/bin:/usr/sbin:/sbin",
               TERM="dumb", NO_COLOR="1", DAY_ONE_MAC_STATE_ROOT=str(home / "state"),
               DAY_ONE_MAC_STATE_DIR=str(home / "state"))
    output = exercise(env, b"j \x1b[C \r", "Selected: eza direnv")
    assert "$ brew install direnv" in output and "$ brew install eza" not in output
    exercise(env, b"a\x1b[C \x1b[Dn\r", "Selected: direnv")
    exercise(env, b"k \r", "Selected: zoxide")
    exercise(env, b"lll \r", "Selected: dive")
    exercise(env, b"\r", "nothing selected; no changes made")
    exercise(env, b"q", "Navigation (5/7)", status=10)
    listing = subprocess.run(["/bin/bash", str(SCRIPT), "--list"], env=env,
                             check=True, capture_output=True, text=True).stdout
    assert "lazydocker" in listing and "zoxide" in listing and "[installed]" in listing
    preview = subprocess.run(["/bin/bash", str(SCRIPT), "--packages", "eza,direnv", "--dry-run"],
                             env=env, check=True, capture_output=True, text=True).stdout
    assert "Selected: eza direnv" in preview and "lazydocker" not in preview
    assert not (home / "state").exists(), "read-only selector wrote state"

print("PASS: compact CLI categories, retained selections, category toggles, wrapping and read-only previews")
