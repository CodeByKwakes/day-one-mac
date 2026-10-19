#!/usr/bin/env bash
# Shared scalar preference catalogue; no inspection or writes on source.
preference_spec() {
  case "$1" in
    finder-hidden) printf 'com.apple.finder\tAppleShowAllFiles\tbool\t1' ;;
    finder-extensions) printf 'NSGlobalDomain\tAppleShowAllExtensions\tbool\t1' ;;
    finder-path) printf 'com.apple.finder\tShowPathbar\tbool\t1' ;;
    finder-status) printf 'com.apple.finder\tShowStatusBar\tbool\t1' ;;
    finder-list) printf 'com.apple.finder\tFXPreferredViewStyle\tstring\tNlsv' ;;
    dock-size) printf 'com.apple.dock\ttilesize\tfloat\t44' ;;
    dock-right) printf 'com.apple.dock\torientation\tstring\tright' ;;
    dock-magnification-off) printf 'com.apple.dock\tmagnification\tbool\t0' ;;
    dock-autohide) printf 'com.apple.dock\tautohide\tbool\t1' ;;
    dock-scale-effect) printf 'com.apple.dock\tmineffect\tstring\tscale' ;;
    dock-minimize-into-app) printf 'com.apple.dock\tminimize-to-application\tbool\t1' ;;
    dock-no-launch-animation) printf 'com.apple.dock\tlaunchanim\tbool\t0' ;;
    dock-show-indicators) printf 'com.apple.dock\tshow-process-indicators\tbool\t1' ;;
    dock-no-recents) printf 'com.apple.dock\tshow-recents\tbool\t0' ;;
    keyboard-fast) printf 'NSGlobalDomain\tKeyRepeat\tint\t2\nNSGlobalDomain\tInitialKeyRepeat\tint\t15' ;;
    autocorrect-off) printf 'NSGlobalDomain\tNSAutomaticSpellingCorrectionEnabled\tbool\t0' ;;
    screenshot-location) printf 'com.apple.screencapture\tlocation\tstring\t%s/Pictures/Screenshots' "$HOME" ;;
    *) return 1 ;;
  esac
}
