#!/usr/bin/env bash
# One entry point for this repository's helper, patch, and test scripts.
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
touch_test="$root/patches/001-touch/test/test-touchscreen.sh"
touch_fix="$root/patches/001-touch/fix/install-touchscreen.sh"
kernel=7.3.0-rc3+
dtb="/boot/dtbs/$kernel/qcom/x1e80100-microsoft-romulus15.dtb"
original_sha=fcd6ed25e8d3adf76aa232e911f91162afe8a006d620aa85c72a607c4a31b508
patched_sha=91760f726a8df2bce9cdb63ed58f9a91bf4f5523f9566e4e4c1cab8c7eaef771

usage() {
    cat <<'EOF'
Usage: ./surface.sh <command>

Setup:
  wifi-board        Repack ath12k board-2.bin for WiFi (scripts/fix-board-2-wifi.sh)
  firmware          Extract Laptop 7 DSP/GPU firmware (scripts/romulus-firmware-extract.sh)

Touchscreen (15-inch Laptop 7, ELLX 7.3.0-rc3+ only, experimental):
  touch-status      Show whether the test entry and/or normal-boot patch are installed
  touch-check       Build and validate the overlay offline; changes nothing
  touch-test        Add a separate EXPERIMENTAL GRUB entry to try it once
  touch-reset       Delete the separate test GRUB entry and test DTB
  touch-install     Apply the tested patch to the normal default boot
  touch-restore     Restore the original normal-boot DTB
  touch-remove-all  Remove everything: restore the normal DTB and reset the test

Commands that change the system ask for sudo and never reboot automatically.
EOF
}

as_root() {
    if [[ $EUID -eq 0 ]]; then
        bash "$@"
    else
        sudo bash "$@"
    fi
}

sha_of() {
    local sum
    sum=$(sha256sum "$1")
    printf '%s\n' "${sum%% *}"
}

touch_status() {
    printf 'Normal boot DTB: '
    if [[ ! -f "$dtb" ]]; then
        printf 'missing (%s)\n' "$dtb"
    else
        case "$(sha_of "$dtb")" in
            "$original_sha") printf 'original (touchscreen patch NOT installed)\n' ;;
            "$patched_sha") printf 'PATCHED (touchscreen enabled on normal boot)\n' ;;
            *) printf 'unknown contents (not managed by these scripts)\n' ;;
        esac
    fi
    printf 'Original backup: '
    [[ -f "$dtb.before-touchscreen" ]] && printf 'present\n' || printf 'none\n'
    printf 'Test GRUB entry: '
    [[ -f /boot/grub/custom.cfg ]] && printf 'present (/boot/grub/custom.cfg)\n' || printf 'none\n'
    printf 'Test DTB:        '
    [[ -f /boot/romulus15-touchscreen-test.dtb ]] && printf 'present\n' || printf 'none\n'
}

[[ $# -eq 1 ]] || { usage >&2; exit 1; }
case "$1" in
    wifi-board) as_root "$root/scripts/fix-board-2-wifi.sh" ;;
    firmware) as_root "$root/scripts/romulus-firmware-extract.sh" ;;
    touch-status) touch_status ;;
    touch-check)
        bash "$touch_test" --check
        bash "$touch_fix" --check
        ;;
    touch-test) as_root "$touch_test" --install ;;
    touch-reset) as_root "$touch_test" --reset ;;
    touch-install) as_root "$touch_fix" --install ;;
    touch-restore) as_root "$touch_fix" --restore ;;
    touch-remove-all)
        if [[ -f "$dtb.before-touchscreen" ]]; then
            as_root "$touch_fix" --restore
        else
            printf 'No normal-boot patch backup found; normal DTB left unchanged.\n'
        fi
        as_root "$touch_test" --reset
        touch_status
        ;;
    -h|--help|help) usage ;;
    *) usage >&2; exit 1 ;;
esac
