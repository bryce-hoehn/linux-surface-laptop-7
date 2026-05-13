# Linux on the Surface Laptop 7 (ARM)

These are my notes for getting Linux working on the Surface Laptop 7 (ARM).

Based on the [Ubuntu Concept image](https://discourse.ubuntu.com/t/ubuntu-24-10-concept-snapdragon-x-elite/48800/1)

**Disclaimer:** I have no experience with upstreaming patches, the patch review process, Linux coding conventions, etc. **at all**, so for now I'm just documenting everything here in the hope that more knowledgable people can help!

## What's working

| **Feature**               | **Working?** | **Notes**                                                                                                                                                  |
|---------------------------|:------------:|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NVMe                      |       ✅      |                                                                                                                                                            |
| Graphics                  |       ✅      | Requires firmware                                                                                          |
| Backlight                 |       ✅      |                                                                                                                                                    |
| USB                       |   ✅  | USB-A and USB-C ports are working. Have not tested USB over Surface Connector              |
| USB-C display output      |       ✅      |        [#11](https://github.com/bryce-hoehn/linux-surface-laptop-7/issues/11)                                                                                                                                                    |
| Wi-Fi                     |       ✅      | Requires firmware and either the ELLX prebuilt kernel or the manual rfkill patch below        |
| Bluetooth                 |       ✅      |  Requires firmware [#6](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/6)                                                                                                                                                          |
| Audio                     |       ✅      |  [#2](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/2) |
| Touchscreen               |       ❌      |     [#13](https://github.com/bryce-hoehn/linux-surface-laptop-7/issues/13)                                                                                                                                                       |
| Touchpad               |       ⚠️      |     Works with the ELLX `iptsd` package, but can still break after suspend and may need recalibration or a Windows reboot to reset            |
| Keyboard             |       ✅      |                                                                                        |
| Lid switch/suspend        |       ✅      | https://github.com/giantdwarf17/linux-surface-laptop-7/issues/7#issuecomment-2750000739                                                                                                                                      |
| Webcam |       ✅      |    Rquires device tree patches [0004](patches/0004-OV02C10-camera-device-tree.patchpatches/0004-OV02C10-camera-device-tree.patch) & [0005](patches/0005-OV02C10-camera-metadata.patch) https://github.com/giantdwarf17/linux-surface-laptop-7/issues/4              |
| RTC |  ✅  | https://github.com/giantdwarf17/linux-surface-laptop-7/issues/8 |

> [!WARNING]
> Without installing the firmware, many hardware components will be broken!

## Quick Start

Tested working on the [Ubuntu concept image](https://people.canonical.com/~platform/images/ubuntu-concept/) for Ubuntu 26.04. The easiest setup right now is the community-maintained ELLX prebuilts for the Surface Laptop 7 X1 Elite at <https://public.hgci.org/software/ELLX/>. They are built for Ubuntu 26.04 and should also work on Debian.

These prebuilts currently cover:
* Wi-Fi
* Bluetooth
* Trackpad
* GPU

> [!IMPORTANT]
> Keep your Windows install if you can. If the trackpad gets into a bad state, the easiest known reset right now is to reboot into Windows and then back into Linux.

Steps:
* Allocate disk partition space for dual booting (**highly recommended** with bleeding-edge unsupported Linux).
* Install [Ventoy](https://www.ventoy.net/en/download.html) to a USB and drag/drop the ISO afterwards. Ventoy is required to enable keyboard support in GRUB.
* Reboot, select the ISO with Ventoy, and install Ubuntu.
* Download the latest matching kernel packages from `https://public.hgci.org/software/ELLX/kernels/`. At the time of writing these are:
  * `kernels/7.0.0-rc4-11/linux-headers-7.0.0-rc4+_7.0.0~rc4-gc0ce08f6e526-42_arm64.deb`
  * `kernels/7.0.0-rc4-11/linux-image-7.0.0-rc4+_7.0.0~rc4-gc0ce08f6e526-42_arm64.deb`
* Install the kernel packages:

```bash
sudo apt install ./*.deb
```

* Install the firmware from `surface-laptop-7-firmware/proprietary-firmware.tar.gz`:

```bash
sudo tar -xf proprietary-firmware.tar.gz -C /
```

* Install `iptsd` from `iptsd/alex-lentz_iptsd/iptsd_3.1.0-1_arm64.deb` and reboot.
* Calibrate the trackpad using the instructions from <https://github.com/alex-lentz/iptsd>.

Sources:
* ELLX kernel source: <https://github.com/ProgrammerIn-wonderland/ELLX-Kernel>
* `iptsd` source: <https://github.com/alex-lentz/iptsd>

> [!NOTE]
> Trackpad support is much better with this setup, but suspend can still leave it in a broken state.

## Manual Wifi / Kernel Setup

If you want to build the kernel yourself instead of using the ELLX prebuilts, the older manual notes are below.

* Download and automatically repack board-2.bin by running [fix-board-2-wifi.sh](https://github.com/giantdwarf17/linux-surface-laptop-7/blob/main/fix-board-2-wifi.sh)

```bash
chmod +x fix-board-2-wifi.sh
./fix-board-2-wifi.sh
```

* Build kernel and install [0001-wifi-rfkill-hack.patch](https://github.com/bryce-hoehn/linux-surface-laptop-7/blob/main/patches/0001-wifi-rfkill-hack.patch)
```bash
# Install dependencies
sudo apt install git build-essential fakeroot devscripts equivs flex bison bc libssl-dev libelf-dev dwarves dpkg-dev debhelper rsync kmod cpio fakeroot

# Clone most recent concept kernel
git clone git.launchpad.net/~ubuntu-concept/ubuntu/+source/linux/+git/resolute -b qcom-x1e-7.0
patch -p1 < 0001-wifi-rfkill-hack.patch

# Build & install
fakeroot .debian/rules binary-qcom.x1e
sudo apt install ./*.deb 
sudo reboot
```

## Tips & Tricks

### Fixing Firefox crashes
If you experience any issues with Firefox, try switching from snap to the .deb or flatpak package.

# Credits
* dwhinham for readme template and patches from Surface Pro 11: https://github.com/dwhinham/linux-surface-pro-11
* qzed from linux-surface: https://github.com/linux-surface/linux-surface
* everyone from the ubuntu-concept issue thread: https://bugs.launchpad.net/ubuntu-concept/+bug/2084951
