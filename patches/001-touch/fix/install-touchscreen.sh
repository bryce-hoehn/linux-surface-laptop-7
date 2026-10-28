#!/usr/bin/env bash
set -euo pipefail

kernel=7.3.0-rc3+
directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tree="/boot/dtbs/$kernel/qcom/x1e80100-microsoft-romulus15.dtb"
backup="$tree.before-touchscreen"
overlay="$directory/romulus15-touchscreen.dtso"
original_sha=fcd6ed25e8d3adf76aa232e911f91162afe8a006d620aa85c72a607c4a31b508
# SHA-256 of the DTB that was boot-tested through the separate GRUB entry.
tested_sha=91760f726a8df2bce9cdb63ed58f9a91bf4f5523f9566e4e4c1cab8c7eaef771
mode=${1:---check}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: bash install-touchscreen.sh [--check|--install|--restore]

  --check    Build and verify against the tested checksum; change nothing (default).
  --install  Back up and patch the DTB used by normal GRUB entries (sudo).
  --restore  Restore the original backed-up DTB (sudo).

Only for the tested ELLX 7.3.0-rc3+ Romulus15 tree.
Does not modify GRUB configuration, reboot, or apply the overlay live.
Kernel/package updates may replace the patched tree.
EOF
}

[[ $# -le 1 ]] || { usage >&2; exit 1; }
case "$mode" in
    --check|--install|--restore) ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
esac
[[ "$mode" == --check || $EUID -eq 0 ]] ||
    die "Run using sudo bash \"$0\" $mode"

for tool in dtc fdtoverlay fdtget sha256sum readlink cmp mktemp; do
    command -v "$tool" >/dev/null || die "Required tool missing: $tool"
done
[[ "$(uname -r)" == "$kernel" ]] || die "Expected running kernel $kernel."
[[ -r /proc/device-tree/model ]] || die "Device-tree model is missing."
[[ "$(tr -d '\0' < /proc/device-tree/model)" == 'Microsoft Surface Laptop 7 (15 inch)' ]] ||
    die "Only the 15-inch Laptop 7 is supported."
[[ -f "$tree" && ! -L "$tree" ]] || die "Expected a regular DTB at $tree."
[[ "$(readlink -f "/boot/dtb-$kernel")" == "$tree" &&
    "$(readlink -f /boot/dtb)" == "$tree" ]] ||
    die "Normal boot DTB links do not resolve to the expected tree."
[[ ! -L "$backup" ]] || die "Backup path is a symlink; refusing."

sha_of() {
    local sum
    sum=$(sha256sum "$1")
    printf '%s\n' "${sum%% *}"
}

check_original() {
    [[ "$(sha_of "$1")" == "$original_sha" ]] ||
        die "$1 is not the original tested base DTB; nothing installed."
}

source_tree="$tree"
if [[ -e "$backup" ]]; then
    [[ -f "$backup" ]] || die "Backup is not a regular file."
    check_original "$backup"
    source_tree="$backup"
fi

tmp=$(mktemp -d)
staged=
cleanup() {
    if [[ -n "$staged" ]]; then
        rm -f -- "$staged"
    fi
    rm -f -- "$tmp/overlay.dtbo" "$tmp/patched.dtb"
    rmdir -- "$tmp"
}
trap cleanup EXIT

if [[ "$mode" == --restore ]]; then
    [[ -f "$backup" ]] || die "No original backup exists."
    staged=$(mktemp "$tree.restore.XXXXXX")
    install -m 0644 -- "$backup" "$staged"
    mv -f -- "$staged" "$tree"
    staged=
    printf 'Restored original DTB. Backup retained at %s\n' "$backup"
    printf 'Normal GRUB entries will use it on the next boot. No reboot performed.\n'
    exit 0
fi

check_original "$source_tree"
[[ -r "$overlay" ]] || die "Overlay is missing: $overlay"
dtc -@ -I dts -O dtb -o "$tmp/overlay.dtbo" "$overlay"
fdtoverlay -i "$source_tree" -o "$tmp/patched.dtb" "$tmp/overlay.dtbo"
[[ "$(sha_of "$tmp/patched.dtb")" == "$tested_sha" ]] ||
    die "Rebuilt DTB differs from the previously tested candidate; refusing installation."
[[ "$(fdtget "$tmp/patched.dtb" /soc@0/geniqup@ac0000/spi@a88000 status)" == okay ]] ||
    die "Touchscreen controller is not enabled."
if ! cmp -s -- "$tree" "$source_tree" && ! cmp -s -- "$tree" "$tmp/patched.dtb"; then
    die "Current DTB has other changes; refusing to overwrite them."
fi
printf 'PASS: rebuilt patch matches the tested touchscreen DTB exactly.\n'
if [[ "$mode" == --check ]]; then
    printf 'No boot files changed.\n'
    exit 0
fi
if cmp -s -- "$tree" "$tmp/patched.dtb"; then
    printf 'Normal boot DTB is already patched. Nothing changed.\n'
    exit 0
fi

printf '\nThis patches the device tree used by your NORMAL boot entries.\n'
printf 'They will no longer provide an unpatched fallback for this kernel.\n'
printf 'Keep recovery media available; restore the backup from recovery if boot fails.\n'
read -r -p 'Type APPLY to patch normal boot: ' answer
[[ "$answer" == APPLY ]] || die "Cancelled; no boot files changed."

if [[ ! -e "$backup" ]]; then
    (set -o noclobber; cat "$tree" > "$backup")
    chmod 0644 "$backup"
    check_original "$backup"
fi
staged=$(mktemp "$tree.install.XXXXXX")
install -m 0644 -- "$tmp/patched.dtb" "$staged"
mv -f -- "$staged" "$tree"
staged=
[[ "$(sha_of "$tree")" == "$tested_sha" ]] || die "Installed DTB verification failed."
printf '\nPatched normal boot DTB; original backup: %s\n' "$backup"
printf 'Choose your normal GRUB entry after restarting. No update-grub is needed.\n'
printf 'Undo: sudo bash "%s" --restore\n' "$0"
printf 'This applies only to %s; kernel updates need separate validation.\n' "$kernel"
