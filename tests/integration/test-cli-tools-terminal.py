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


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "src/modules/configure-cli-tools.sh"


def exercise(env, keys, expected, status=0, args=("--dry-run",), command=None,
             ready=b"q: quit", check_category=True):
    pid, master = pty.fork()
    if pid == 0:
        target = command or ROOT / "scripts/day-one-mac"
        arguments = list(args) if command else ["cli-tools", *args]
        os.execve("/bin/bash", ["/bin/bash", str(target), *arguments], env)
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
            if not sent and ready in output:
                first = output.decode()
                if check_category:
                    assert "Navigation (5/7)" in first
                    assert "lazydocker" not in first and "shellcheck" not in first
                assert first.count("\n") < 25, first
                if env.get("COLUMNS") == "40":
                    lines = first.splitlines()
                    assert len(lines) <= 18, first
                    assert all(len(line) <= 40 for line in lines), first
                assert "━━" not in first
                if env.get("TERM") == "dumb" or env.get("DAY_ONE_MAC_ASCII") == "1":
                    assert "🎛" not in first
                os.write(master, keys)
                sent = True
        else:
            raise AssertionError("CLI selector timed out: " + output.decode())
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
               TERM="dumb", NO_COLOR="1", COLUMNS="80", LINES="24", DAY_ONE_MAC_STATE_ROOT=str(home / "state"),
               DAY_ONE_MAC_STATE_DIR=str(home / "state"))
    output = exercise(env, b"j \x1b[C \r", "Selected: eza direnv")
    assert "$ brew install direnv" in output and "$ brew install eza" not in output
    exercise(env, b"a\x1b[C \x1b[Dn\r", "Selected: direnv")
    exercise(env, b"k \r", "Selected: zoxide")
    exercise(env, b"lll \r", "Selected: dive")
    exercise(env, b"\r", "nothing selected; no changes made")
    exercise(env, b"q", "Navigation (5/7)", status=10)
    exercise(env, b"b", "Navigation (5/7)", status=10)
    narrow = dict(env, COLUMNS="40", LINES="18", DAY_ONE_MAC_ASCII="1")
    output = exercise(narrow, b"k \r", "Selected: zoxide")
    assert "Item 1 of 6 (showing 1-1)" in output
    assert "Item 6 of 6 (showing 6-6)" in output
    assert "\x1b" not in output, "TERM=dumb emitted terminal controls"
    colourless = dict(env, TERM="xterm-256color")
    output = exercise(colourless, b"q", "Navigation (5/7)", status=10)
    assert "\x1b[36m" not in output, "NO_COLOR was ignored"
    assert "🎛" in output, "NO_COLOR should retain the heading icon"
    coloured = dict(env, TERM="xterm-256color")
    coloured.pop("NO_COLOR", None)
    output = exercise(coloured, b"q", "Navigation (5/7)", status=10)
    assert "\x1b[36m" in output and "\x1b[1m" in output
    assert "🎛" in output, "interactive heading icon is missing"
    # Run the production wizard selectors with private, harmless catalogues.
    # Extract only function definitions; never execute setup or preferences.
    print("PASS: CLI selector terminal interaction")
