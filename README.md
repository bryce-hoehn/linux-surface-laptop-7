# Linux on the Surface Laptop 7 (ARM)

Community notes, configuration, and experimental fixes for Linux on the
Microsoft Surface Laptop 7 (X1 Elite / Romulus).

> [!WARNING]
> Linux support is still experimental. Hardware support depends on the laptop
> model, kernel, firmware, and userspace. Keep recovery media available and,
> if possible, retain a Windows installation. Use system-changing scripts at
> your own risk.

## At a glance

| Hardware | Status | Notes |
| --- | --- | --- |
| NVMe, graphics, backlight | Working | Graphics requires firmware. |
| USB and USB-C display | Working | USB over the Surface Connector has not been tested. See [issue #11](https://github.com/bryce-hoehn/linux-surface-laptop-7/issues/11). |
| Wi-Fi and Bluetooth | Working | Requires firmware and a compatible kernel. See [Wi-Fi setup](#wi-fi-and-firmware). |
| Audio | Working | See [issue #2](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/2). |
| Touchpad and keyboard | Working | Touchpad works with ELLX `iptsd`; calibration may be needed. |
| Lid switch and suspend | Working | See [suspend notes](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/7#issuecomment-2750000739). |
| RTC | Working | See [issue #8](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/8). |
| Touchscreen | Experimental | Finger touch and gestures tested on one 15-inch model with ELLX `7.3.0-rc3+`. Pen is untested. See the [touchscreen guide](docs/touchscreen.md) and [issue #13](https://github.com/bryce-hoehn/linux-surface-laptop-7/issues/13). |
| Camera | Experimental | Requires the outgoing kernel patches and libcamera tuning in [config/OV02C10-camera](config/OV02C10-camera/). See [issue #4](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/4). |

Firmware is required for several components. The setup notes below are
community-contributed and can become outdated; confirm kernel and package
versions at the linked sources before installing anything.

## Getting started

The easiest currently documented route is the community-maintained
[ELLX prebuilt kernels and fixes](https://public.hgci.org/software/ELLX/), used
with the [Ubuntu concept image](https://people.canonical.com/~platform/images/ubuntu-concept/)
for Ubuntu 26.04. The prebuilts cover Wi-Fi, Bluetooth, touchpad, and GPU.
They are built for Ubuntu 26.04 and may also work on Debian.

1. Prefer a dual-boot setup and keep recovery media available.
2. Install Ubuntu using the [Ubuntu concept image](https://people.canonical.com/~platform/images/ubuntu-concept/).
   Ventoy is reported to provide keyboard support in GRUB.
3. Install matching kernel packages from the
   [ELLX kernel downloads](https://public.hgci.org/software/ELLX/kernels/).
   Follow the current ELLX instructions rather than relying on old package
   filenames or kernel versions copied into older guides.
4. Install the proprietary firmware archive supplied with the ELLX firmware
   bundle. Review the archive contents and its instructions before extracting
   it to `/`.
5. Install the matching ELLX `iptsd` package, reboot, then calibrate the
   touchpad if needed. The ELLX download page also has
   [suspend and resume fixes](https://public.hgci.org/software/ELLX/fixes/).

If the touchpad becomes unusable after suspend, the known recovery is to boot
Windows and then return to Linux. See the ELLX fixes before relying on suspend.

## Repository map

| Path | Contents |
| --- | --- |
| [surface.sh](surface.sh) | Main entry point for the helper commands below. |
| [scripts/](scripts/) | Wi-Fi board-data repacking and Microsoft firmware extraction helpers. |
| [patches/](patches/) | Kernel patches, touchscreen overlay tooling, and patch lifecycle folders. See the [patch index](docs/patches.md). |
| [config/](config/) | Touchpad calibration and OV02C10 camera configuration / libcamera notes. |
| [docs/touchscreen.md](docs/touchscreen.md) | Detailed touchscreen compatibility, testing, installation, and recovery guide. |

Patch status is intentional: root-level numbered patches are older/manual
setup patches; `outgoing/` contains patches retained for review or submission;
`upstreamed/` is historical and retained for reference. Check
[docs/patches.md](docs/patches.md) and each patch's current status before
applying it.

## Helper commands

Run `./surface.sh help` for the built-in usage summary. Commands that modify
the system use `sudo`; none reboot automatically.

| Command | Purpose |
| --- | --- |
| `./surface.sh wifi-board` | Download, modify, and install ath12k `board-2.bin`. |
| `./surface.sh firmware` | Extract selected DSP/GPU files from the Microsoft firmware MSI. |
| `./surface.sh touch-status` | Report the touchscreen test and normal-boot installation state. |
| `./surface.sh touch-check` | Build and validate the touchscreen overlay offline. |
| `./surface.sh touch-test` | Install a separately selectable experimental GRUB entry. |
| `./surface.sh touch-reset` | Remove the managed touchscreen test entry and DTB. |
| `./surface.sh touch-install` | Apply the tested overlay to the normal-boot DTB. |
| `./surface.sh touch-restore` | Restore the saved normal-boot DTB. |
| `./surface.sh touch-remove-all` | Restore the original DTB if needed and remove the test entry. |

The touchscreen commands are only for the 15-inch model with the exact ELLX
`7.3.0-rc3+` setup documented in the
[touchscreen guide](docs/touchscreen.md). Do not use them on another model or
kernel.

## Wi-Fi and firmware

For the manual kernel route, [fix-board-2-wifi.sh](scripts/fix-board-2-wifi.sh)
repackages the ath12k board data. The older Wi-Fi rfkill patch is
[patches/0001-wifi-rfkill-hack.patch](patches/0001-wifi-rfkill-hack.patch).
Check [docs/patches.md](docs/patches.md) for its status and limitations before
building or applying it.

The firmware extraction helper downloads a Microsoft MSI and copies selected
files into `/lib/firmware/updates/qcom/x1e80100/microsoft/`. It requires
`wget` and `msiextract`; review the script and confirm that its fixed MSI URL
is still appropriate before running `./surface.sh firmware`.

## Other notes

- **Touchscreen:** follow the safe, staged workflow in the
  [touchscreen guide](docs/touchscreen.md); do not copy a DTB over `/boot` by
  hand.
- **Camera:** see [config/OV02C10-camera/README.md](config/OV02C10-camera/README.md)
  for tuning and libcamera build notes.
- **Touchpad calibration:** see [config/touchpad/](config/touchpad/) and the
  ELLX `iptsd` instructions.
- **Random Wi-Fi MAC address:** ELLX prebuilts and manual setup may generate a
  new address each boot. An experimental external patch is available at
  [valeronm/sl7-mac](https://github.com/valeronm/sl7-mac).
- **Firefox crashes:** try a non-Snap build, such as the distribution `.deb`
  or Flatpak package.

## References and credits

- [ELLX kernel source](https://github.com/ProgrammerIn-wonderland/ELLX-Kernel),
  [prebuilt packages and fixes](https://public.hgci.org/software/ELLX/), and
  [iptsd](https://github.com/alex-lentz/iptsd).
- Touchscreen research: [dwhinham](https://github.com/dwhinham),
  [denisix](https://github.com/denisix), and the
  [published Romulus ACPI tables](https://github.com/aarch64-laptops/build/tree/master/misc/microsoft-surface-romulus13_and_15).
- README template and Surface Pro 11 patches:
  [dwhinham/linux-surface-pro-11](https://github.com/dwhinham/linux-surface-pro-11).
- [linux-surface](https://github.com/linux-surface/linux-surface),
  [valeronm/sl7-mac](https://github.com/valeronm/sl7-mac), and contributors to
  the [Ubuntu concept issue thread](https://bugs.launchpad.net/ubuntu-concept/+bug/2084951).
