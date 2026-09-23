#!/usr/bin/env bash
# Read the APFS backing-store relationship from diskutil property lists.
#
# macOS has emitted more than one key shape for this relationship. Keeping the
# compatibility logic here makes it independently testable and prevents a real
# external APFS drive from being mistaken for a virtual disk image.

plist_raw() {
  /usr/bin/plutil -extract "$2" raw -o - "$1" 2>/dev/null || true
}

mounted_device_for_path() {
  local target_path="$1" mounted_device
  [[ -e "$target_path" || -L "$target_path" ]] || return 1

  # diskutil accepts a mount point or disk identifier, but it does not reliably
  # accept an ordinary folder below a mounted volume. POSIX df resolves any
  # existing file or folder to the device that contains it; its first data
  # column is safe to read even when the path contains spaces or Unicode.
  mounted_device="$(/bin/df -P "$target_path" 2>/dev/null \
    | /usr/bin/awk 'NR == 2 { print $1; exit }')"
  case "$mounted_device" in
    /dev/*) printf '%s\n' "$mounted_device" ;;
    *) return 1 ;;
  esac
}

apfs_physical_store_from_plist() {
  local plist_file="$1" store_identifier plist_key

  # `diskutil info -plist` commonly uses APFSPhysicalStore inside the
  # APFSPhysicalStores array. Other diskutil plist forms use DeviceIdentifier,
  # PhysicalStores, or DesignatedPhysicalStore.
  for plist_key in \
    'APFSPhysicalStores.0.APFSPhysicalStore' \
    'APFSPhysicalStores.0.DeviceIdentifier' \
    'PhysicalStores.0.DeviceIdentifier' \
    'DesignatedPhysicalStore'; do
    store_identifier="$(plist_raw "$plist_file" "$plist_key")"
    if [[ -n "$store_identifier" ]]; then
      printf '%s\n' "$store_identifier"
      return 0
    fi
  done
  return 1
}
