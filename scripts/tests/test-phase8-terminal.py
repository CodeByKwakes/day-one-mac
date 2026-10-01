#!/usr/bin/env python3
"""Exercise the real Phase 8 Node probe followed by its prompt on a PTY.

Pipe-only tests miss SIGTTIN: a nested interactive zsh can leave the Bash
runner outside the terminal's foreground process group after external jobs.
No real user startup files, Node tools, keys, accounts or setup state are used.
"""

import errno
import os
from pathlib import Path
import pty
import re
import select
import shlex
import signal
import tempfile
import time


PHASE = Path(__file__).resolve().parents[1] / "phases/08-verification.sh"
source = PHASE.read_text()
probe = re.search(r'^  uses_node && report_check "Node, npm and pnpm" .+$', source, re.M)
if probe is None:
    raise SystemExit("FAIL: cannot locate the production Node verification probe")


def exercise(root, failure):
    home = root / ("failure" if failure else "success")
    binary = home / "bin"
    binary.mkdir(parents=True)
    # Keep interactive/login startup enabled so dropping -i or -l cannot make
    # the test pass by accidentally skipping the user's environment.
    (home / ".zprofile").write_text("export DOM_TEST_LOGIN=yes\n")
    (home / ".zshrc").write_text(
        'export PATH="$HOME/bin:$PATH"\nexport DOM_TEST_INTERACTIVE=yes\n'
    )
    for command in ("node", "npm", "pnpm"):
        tool = binary / command
        tool.write_text(
            '#!/bin/sh\n[ "$DOM_TEST_LOGIN:$DOM_TEST_INTERACTIVE" = yes:yes ] || exit 97\n'
            '[ "$1" = --version ] || exit 98\n'
            f'exit {7 if failure and command == "npm" else 0}\n'
        )
        tool.chmod(0o700)
    binary.joinpath("zsh").symlink_to("/bin/zsh")
    runner = home / "probe.sh"
    runner.write_text(
        'set -euo pipefail\nprintf "RUNNER_PID=%s\\n" "$$"\n'
        f"source {shlex.quote(str(PHASE))}\n"
        'STATE_DIR="$HOME"\nVERIFY_FAILURES=0\nASSUME_YES=0\n'
        'uses_node(){ return 0; }\nphase_gate_failed(){ :; }\n'
        'configuration_shell_target(){ printf "/bin/zsh\\n"; }\n'
        + probe.group(0) + '\n'
        + f'[[ "$VERIFY_FAILURES" == {1 if failure else 0} ]]\n'
        + f"grep -Fq '| Node, npm and pnpm | {'FAIL' if failure else 'PASS'} |' "
        '"$STATE_DIR/verification.md"\n'
        'if confirm_retained_ssh_key fixture-only; then\n'
        '  printf "PROMPT_ACCEPTED\\n"\n'
        'else exit 99; fi\n'
    )
    env = {
        "HOME": str(home), "ZDOTDIR": str(home),
        "PATH": f"{binary}:/usr/bin:/bin:/usr/sbin:/sbin",
        "TERM": "dumb", "PS1": "READY> ", "PS2": "MORE> ",
    }
    pid, master = pty.fork()
    if pid == 0:
        os.execve("/bin/zsh", ["/bin/zsh", "-dfi"], env)
    output = bytearray()
    runner_pid = None
    try:
        def until(marker):
            nonlocal runner_pid
            deadline = time.monotonic() + 10
            while marker not in output:
                if time.monotonic() >= deadline:
                    raise AssertionError(f"timed out waiting for {marker!r}")
                if not select.select([master], [], [], 0.1)[0]:
                    continue
                try:
                    chunk = os.read(master, 65536)
                except OSError as exc:
                    if exc.errno != errno.EIO:
                        raise
                    chunk = b""
                if not chunk:
                    raise AssertionError("terminal closed before completion")
                output.extend(chunk)
                match = re.search(rb"RUNNER_PID=(\d+)", output)
                if match:
                    runner_pid = int(match.group(1))
                if b"suspended" in output or b"Stopped" in output:
                    raise AssertionError("Node probe suspended the following prompt")

        until(b"READY> ")
        # A foreground job started by a genuine interactive parent shell is
        # necessary; merely attaching a PTY to subprocess.run misses the bug.
        os.write(master, f"/bin/bash {shlex.quote(str(runner))}\n".encode())
        until(b"Type retain, or Return to leave REVIEW: ")
        os.write(master, b"retain\n")
        until(b"PROMPT_ACCEPTED")
    except AssertionError as exc:
        raise AssertionError(f"{exc}\n{output.decode(errors='replace')}") from exc
    finally:
        # Bound both failed/suspended jobs and the interactive parent. These
        # PIDs belong only to this disposable PTY, never to the caller's shell.
        for child in (runner_pid, pid):
            if child is not None:
                try:
                    os.kill(child, signal.SIGKILL)
                except ProcessLookupError:
                    pass
        os.close(master)
        os.waitpid(pid, 0)


with tempfile.TemporaryDirectory(prefix="day-one-phase8-tty-") as temp:
    for failing_tool in (False, True):
        exercise(Path(temp), failing_tool)
print("PASS: Phase 8 Node success/failure preserves the following terminal prompt")
