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
| Wi-Fi                     |       ✅      | Requires kernel patch [patches/0001-wifi-rfkill-hack.patch](patches/0001-wifi-rfkill-hack.patch)        |
| Bluetooth                 |       ✅      |  [#6](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/6)                                                                                                                                                          |
| Audio                     |       ✅      |  [#2](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/2) |
| Touchscreen               |       ❌      |     [#13](https://github.com/bryce-hoehn/linux-surface-laptop-7/issues/13)                                                                                                                                                       |
| Touchpad               |       ❌      |     https://github.com/giantdwarf17/linux-surface-laptop-7/issues/5            |
| Keyboard             |       ✅      |                                                                                        |
| Lid switch/suspend        |       ✅      | https://github.com/giantdwarf17/linux-surface-laptop-7/issues/7#issuecomment-2750000739                                                                                                                                      |
| Webcam |       ❓      |     https://github.com/giantdwarf17/linux-surface-laptop-7/issues/4              |
| RTC |  ✅  | https://github.com/giantdwarf17/linux-surface-laptop-7/issues/8 |

> [!WARNING]
> Without installing the firmware, many hardware components will be broken!

## Quick Start

Tested working on [Ubuntu concept image](https://people.canonical.com/~platform/images/ubuntu-concept/) success with all versions after Oracular. Resolute (latest) is recommended as earlier versions run into issues with unsupported core (build) packages.

Steps:
* Allocate disk partition space for dual booting **(high recommended** with bleeding-edge unsupported linux).
* Install [Ventoy](https://www.ventoy.net/en/download.html) to a USB and drag/drop the ISO afterwards. Ventoy is required to enable keyboard support in GRUB.
* Reboot, select the ISO with Ventoy, and install Ubuntu.
* Install firmware blobs for Wifi, Bluetooth & GPU using [romulus-firmware-extract.sh](https://github.com/giantdwarf17/linux-surface-laptop-7/blob/main/romulus-firmware-extract.sh) - requires msitools and you will need a tethered internet connect (ethernet or mobile phone).

## Setting up Wifi

* Download and automatically repack board-2.bin by running [fix-board-2-wifi.sh](https://github.com/giantdwarf17/linux-surface-laptop-7/blob/main/fix-board-2-wifi.sh)

```bash
chmod +x fix-board-2.wifi
./fix-board-2-wifi.sh
```

* Build kernel and install [0001-wifi-rfkill-hack.patch](https://github.com/bryce-hoehn/linux-surface-laptop-7/blob/main/patches/0001-wifi-rfkill-hack.patch)
```bash
# Install dependancies
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

### Booting outdated images (Plucky and before)
Attempting to boot the ubuntu-concept image will fail unless you specify the device tree in the GRUB config. 

Press 'e' in grub when it shows the boot options and then replacing '$dtb' with 'devicetree /casper/x1e80100-microsoft-romulus13.dtb'"
**This is not a problem running Resolute or Questing** - only older versions 

### Fixing Firefox crashes
There is an issue in the Firefox snap package that causes it to crash whenever you use the scroll wheel. The workaround is to switch to the .deb version.

I did so by following these instructions: [https://askubuntu.com/a/1404401]

# Credits
* dwhinham for readme template and patches from Surface Pro 11: https://github.com/dwhinham/linux-surface-pro-11
* qzed from linux-surface: https://github.com/linux-surface/linux-surface
* everyone from the ubuntu-concept issue thread: https://bugs.launchpad.net/ubuntu-concept/+bug/2084951
