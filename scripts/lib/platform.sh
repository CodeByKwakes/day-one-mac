#!/usr/bin/env bash
# Platform checks shared by the Day One Mac entry points.

day_one_require_apple_silicon() {
  local process_arch os_major
  [[ "$(uname -s 2>/dev/null || true)" == Darwin ]] || {
    printf 'Day One Mac supports macOS on Apple-silicon Macs only.\n' >&2
    return 1
  }
  process_arch="$(uname -m 2>/dev/null || true)"
  [[ "$process_arch" == arm64 ]] || {
    printf 'Day One Mac requires an Apple-silicon Mac with a native arm64 terminal.\n' >&2
    printf 'Intel Macs are unsupported. On Apple silicon, quit a Rosetta terminal and reopen its native build.\n' >&2
    return 1
  }
  os_major="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
  [[ "$os_major" =~ ^[0-9]+$ && "$os_major" -ge 15 && "$os_major" -le 27 ]] || {
    printf 'Supported dependency range is macOS 15–27; consult the tested-version matrix before rollout.\n' >&2
    return 1
  }
}
