#!/usr/bin/env bash
set -euo pipefail

kernel=7.3.0-rc3+
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
overlay="$script_dir/../fix/romulus15-touchscreen.dtso"
base="/boot/dtbs/$kernel/qcom/x1e80100-microsoft-romulus15.dtb"
candidate=/boot/romulus15-touchscreen-test.dtb
custom=/boot/grub/custom.cfg
marker='# Managed by linux-surface-laptop-7-RKI/patches/001-touch/test/test-touchscreen.sh'
legacy_marker='# Managed by linux-surface-laptop-7-RKI/test-touchscreen.sh'
mode=${1:---check}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: bash test-touchscreen.sh [--check|--install|--reset]

  --check    Build and validate offline only (default; no sudo needed).
  --install  Install a separate experimental GRUB entry (requires sudo).
  --reset    Delete the separate test GRUB entry and test DTB (sudo).
             Safe to repeat; the normal boot DTB is never changed.
  --remove   Alias for --reset.

Only for the 15-inch Surface Laptop 7 running ELLX 7.3.0-rc3+.
No automatic reboot, default-entry change, update-grub, or live GPIO writes.
The installed entry is experimental and may hang or fail to boot.
EOF
}

[[ $# -le 1 ]] || { usage >&2; exit 1; }
case "$mode" in
    --check|--install|--reset|--remove) ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
esac

if [[ "$mode" != --check && $EUID -ne 0 ]]; then
    die "Run this mode using sudo bash \"$0\" $mode"
fi

if [[ "$mode" == --reset || "$mode" == --remove ]]; then
    [[ ! -L "$custom" ]] || die "$custom is a symlink; nothing removed."
    [[ ! -L "$candidate" ]] || die "$candidate is a symlink; nothing removed."
    if [[ -e "$custom" ]]; then
        [[ -f "$custom" ]] || die "$custom is not a regular file; nothing removed."
        IFS= read -r first_line < "$custom" || first_line=
        [[ "$first_line" == "$marker" || "$first_line" == "$legacy_marker" ]] ||
            die "$custom is not managed by this script; nothing removed."
        rm -- "$custom"
        printf 'Removed the separate test GRUB entry: %s\n' "$custom"
    else
        printf 'No test GRUB entry found.\n'
    fi
    if [[ -e "$candidate" ]]; then
        [[ -f "$candidate" ]] || die "$candidate is not a regular file; not removed."
        rm -- "$candidate"
        printf 'Removed the test DTB: %s\n' "$candidate"
    else
        printf 'No test DTB found.\n'
    fi
    printf 'Test reset complete. Normal boot files were not changed.\n'
    exit 0
fi

[[ "$(uname -r)" == "$kernel" ]] || die "Expected running kernel $kernel."
[[ -r /proc/device-tree/model ]] || die "Device-tree model is not available."
model=$(tr -d '\0' < /proc/device-tree/model)
[[ "$model" == 'Microsoft Surface Laptop 7 (15 inch)' ]] ||
    die "Unsupported model: $model"

for tool in dtc fdtoverlay fdtget grub-script-check findmnt mktemp; do
    command -v "$tool" >/dev/null || die "Required tool not found: $tool"
done
[[ -f "$overlay" && -r "$base" ]] || die "Overlay or matching base DTB is missing."
[[ -f "/boot/vmlinuz-$kernel" && -f "/boot/initrd.img-$kernel" ]] ||
    die "Matching kernel or initramfs is missing."
[[ "$(findmnt -n -o TARGET -T /boot)" == / ]] ||
    die "This script only supports /boot on the root filesystem."
[[ "$(findmnt -n -o FSTYPE -T /boot)" == ext4 ]] ||
    die "This script only supports the current ext4 root filesystem."
uuid=$(findmnt -n -o UUID -T /boot)
[[ "$uuid" =~ ^[[:xdigit:]-]+$ ]] || die "Cannot determine a safe boot filesystem UUID."

# Preserve the working boot's arguments, excluding GRUB's informational token.
read -r -a boot_args < /proc/cmdline
cmdline=
for arg in "${boot_args[@]}"; do
    case "$arg" in BOOT_IMAGE=*) continue ;; esac
    cmdline+="${cmdline:+ }$arg"
done
[[ "$cmdline" =~ ^[a-zA-Z0-9_./:=,+@%\ -]+$ ]] ||
    die "Boot arguments need manual GRUB quoting; refusing to generate an entry."
[[ " $cmdline " == *" root=UUID=$uuid "* ]] ||
    die "Running root argument does not match the boot filesystem UUID."

tmp=$(mktemp -d)
cleanup() {
    rm -f -- "$tmp/touchscreen.dtbo" "$tmp/test.dtb" "$tmp/custom.cfg"
    rmdir -- "$tmp"
}
trap cleanup EXIT

dtc -@ -I dts -O dtb -o "$tmp/touchscreen.dtbo" "$overlay"
fdtoverlay -i "$base" -o "$tmp/test.dtb" "$tmp/touchscreen.dtbo"
controller=/soc@0/geniqup@ac0000/spi@a88000
[[ "$(fdtget "$tmp/test.dtb" / compatible)" == 'microsoft,romulus15 qcom,x1e80100' ]] ||
    die "Unexpected base device-tree compatibility."
[[ "$(fdtget "$tmp/test.dtb" "$controller" status)" == okay ]] ||
    die "Merged touchscreen controller is not enabled."
[[ "$(fdtget "$tmp/test.dtb" "$controller/touchscreen@0" compatible)" == hid-over-spi ]] ||
    die "Merged touchscreen child is missing."

cat > "$tmp/custom.cfg" <<EOF
$marker
# Reset using: sudo bash $script_dir/test-touchscreen.sh --reset
set timeout_style=menu
set timeout=15
menuentry 'EXPERIMENTAL: Laptop 7 touchscreen ($kernel)' --id romulus15-touchscreen-test {
    insmod part_gpt
    insmod ext2
    search --no-floppy --fs-uuid --set=root $uuid
    linux /boot/vmlinuz-$kernel $cmdline
    initrd /boot/initrd.img-$kernel
    devicetree $candidate
}
EOF
grub-script-check "$tmp/custom.cfg"
printf 'PASS: overlay compiled, merged, and GRUB entry syntax checked.\n'

if [[ "$mode" == --check ]]; then
    printf 'Offline check only: no boot files or hardware settings changed.\n'
    exit 0
fi

[[ ! -e "$custom" && ! -L "$custom" ]] ||
    die "$custom already exists; refusing to overwrite it. Run --reset first."
[[ ! -L "$candidate" ]] || die "$candidate is a symlink; refusing to overwrite it."
if [[ -e "$candidate" ]] && ! cmp -s -- "$tmp/test.dtb" "$candidate"; then
    die "$candidate already exists with different contents; refusing to overwrite it."
fi
[[ -r /boot/grub/grub.cfg ]] || die "Cannot read the active GRUB configuration."
grep -Eq '^[[:space:]]*source[[:space:]].*/custom\.cfg' /boot/grub/grub.cfg ||
    die "Active GRUB configuration does not source custom.cfg; manual setup is required."
grub-script-check /boot/grub/grub.cfg

printf '\nWARNING: unverified touchscreen pinmux, power/reset, and QSPI configuration.\n'
printf 'This can hang or fail to boot; permanent hardware risk cannot be ruled out.\n'
printf 'Save your work, have recovery media, and keep the normal boot entry available.\n'
printf 'The normal default stays unchanged; the menu will be shown for 15 seconds.\n'
read -r -p 'Type INSTALL to add the separate test entry: ' answer
[[ "$answer" == INSTALL ]] || die "Cancelled; no boot files changed."

install -m 0644 -- "$tmp/test.dtb" "$candidate"
# Publish the entry last, and never overwrite an existing custom configuration.
(set -o noclobber; cat "$tmp/custom.cfg" > "$custom")
chmod 0644 "$custom"
printf '\nInstalled the separate EXPERIMENTAL entry. No reboot was performed.\n'
printf 'Restart when ready, then manually select EXPERIMENTAL in GRUB.\n'
printf 'If it fails, restart and choose the normal entry without editing it.\n'
printf 'Reset: sudo bash "%s" --reset\n' "$0"
