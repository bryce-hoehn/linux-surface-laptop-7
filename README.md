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
| USB                       |   Partially  | USB-A and USB-C ports are working. Have not tested USB over Surface Connector              |
| USB-C display output      |       ❓      |                                                                                                                                                            |
| Wi-Fi                     |       ✅      | Requires kernel patch [patches/0001-wifi-rfkill-hack.patch](patches/0001-wifi-rfkill-hack.patch)        |
| Bluetooth                 |       ✅      |  [#6](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/6)                                                                                                                                                          |
| Audio                     |       ✅      |  [#2](https://github.com/giantdwarf17/linux-surface-laptop-7/issues/2) |
| Touchscreen               |       ❌      |                                                                                                                                                            |
| Touchpad               |       ❌      |     https://github.com/giantdwarf17/linux-surface-laptop-7/issues/5            |
| Keyboard             |       ✅      |                                                                                        |
| Lid switch/suspend        |       ✅      | https://github.com/giantdwarf17/linux-surface-laptop-7/issues/7#issuecomment-2750000739                                                                                                                                      |
| Webcam |       ❓      |     https://github.com/giantdwarf17/linux-surface-laptop-7/issues/4              |
| RTC |  ✅  | https://github.com/giantdwarf17/linux-surface-laptop-7/issues/8 |

> [!WARNING]
> Without installing the firmware, many hardware components will be broken!

### Firmware blobs

Firmware blobs can be installed by running [romulus-firmware-extract.sh](https://github.com/giantdwarf17/linux-surface-laptop-7/blob/main/romulus-firmware-extract.sh) as root. Requires internet access and msitools.

## Tips & Tricks

### Booting the image
Attempting to boot the ubuntu-concept image will fail unless you specify the device tree in the GRUB config. 

Press 'e' in grub when it shows the boot options and then replacing '$dtb' with 'devicetree /casper/x1e80100-microsoft-romulus13.dtb'"

### Fixing Firefox crashes
There is an issue in the Firefox snap package that causes it to crash whenever you use the scroll wheel. The workaround is to switch to the .deb version.

I did so by following these instructions: https://askubuntu.com/a/1404401

# Credits
* dwhinham for readme template and patches from Surface Pro 11: https://github.com/dwhinham/linux-surface-pro-11
* qzed from linux-surface: https://github.com/linux-surface/linux-surface
* everyone from the ubuntu-concept issue thread: https://bugs.launchpad.net/ubuntu-concept/+bug/2084951
