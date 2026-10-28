#!/usr/bin/env bash
set -euo pipefail

FW_URL="https://git.codelinaro.org/clo/ath-firmware/ath12k-firmware/-/raw/main/WCN7850/hw2.0/board-2.bin?ref_type=heads"
BDENCODER_URL="https://raw.githubusercontent.com/qca/qca-swiss-army-knife/master/tools/scripts/ath12k/ath12k-bdencoder"
FW_DIR="/lib/firmware/ath12k/WCN7850/hw2.0"

tmp=$(mktemp -d)
cleanup() {
  popd >/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

pushd "$tmp" >/dev/null

echo "[+] Downloading board-2.bin"
curl -L -o board-2.bin "$FW_URL"

echo "[+] Downloading ath12k-bdencoder"
curl -L -o ath12k-bdencoder "$BDENCODER_URL"
chmod +x ath12k-bdencoder

echo "[+] Extracting board-2.bin"
./ath12k-bdencoder -e board-2.bin

echo "[+] Editing board-2.json"
python3 <<'PY'
import json
import sys

match_name = "bus=pci,vendor=17cb,device=1107,subsystem-vendor=17cb,subsystem-device=3378,qmi-chip-id=2,qmi-board-id=255"
new_name = "bus=pci,vendor=17cb,device=1107,subsystem-vendor=17cb,subsystem-device=1107,qmi-chip-id=2,qmi-board-id=255"

with open("board-2.json", "r", encoding="utf-8") as f:
    data = json.load(f)

found = False
already_present = False

if not isinstance(data, list):
    print("[!] Unexpected JSON structure: top level is not a list", file=sys.stderr)
    sys.exit(1)

for group in data:
    if not isinstance(group, dict):
        continue
    boards = group.get("board", [])
    if not isinstance(boards, list):
        continue

    for entry in boards:
        if not isinstance(entry, dict):
            continue
        names = entry.get("names", [])
        if not isinstance(names, list):
            continue

        if match_name in names:
            found = True
            if new_name in names:
                already_present = True
            else:
                names.append(new_name)
            break

    if found:
        break

if not found:
    print("[!] Target name not found in any board entry", file=sys.stderr)
    sys.exit(1)

if already_present:
    print("[*] New device string already present, nothing to change")
else:
    with open("board-2.json", "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)
        f.write("\n")
    print("[+] Added new device string under matching entry")
PY

echo "[+] Rebuilding board-2.bin"
./ath12k-bdencoder -c board-2.json

echo "[+] Backing up existing firmware"
if [ -f "$FW_DIR/board-2.bin" ]; then
  sudo cp "$FW_DIR/board-2.bin" "$FW_DIR/board-2.bin.bak"
fi
if [ -f "$FW_DIR/board-2.bin.zst" ]; then
  sudo cp "$FW_DIR/board-2.bin.zst" "$FW_DIR/board-2.bin.zst.bak"
fi

echo "[+] Installing rebuilt board-2.bin"
sudo cp board-2.bin "$FW_DIR/board-2.bin"

echo "[+] Reloading ath12k"
sudo modprobe -r ath12k || true
sudo modprobe ath12k

echo "[+] Done"
