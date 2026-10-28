# Patch index

This directory contains patches at different stages and for different kernel
trees. A patch being present here does not mean it is upstream, current, or
safe to apply to an arbitrary kernel. Read its header and check its target
kernel before use.

## Patch lifecycle

| Location | Meaning |
| --- | --- |
| [`patches/`](../patches/) root | Older/manual patches kept at their original paths for existing instructions and references. |
| [`patches/outgoing/`](../patches/outgoing/) | Work intended for submission or review; not a declaration that it has been submitted or accepted. |
| [`patches/upstreamed/`](../patches/upstreamed/) | Historical patches retained for context; do not reapply if the change is already in your kernel. |
| [`patches/001-touch/`](../patches/001-touch/) | Separate device-tree overlay and guarded test/install scripts for one exact 15-inch ELLX kernel setup. See the [touchscreen guide](touchscreen.md). |

## Root-level patches

| Patch | Purpose | Notes |
| --- | --- | --- |
| [`0001-wifi-rfkill-hack.patch`](../patches/0001-wifi-rfkill-hack.patch) | Bypasses the ath12k rfkill configuration path for the Wi-Fi setup described by the older manual kernel instructions. | A targeted workaround, not a general Wi-Fi fix. |
| [`0002-hid-over-spi.patch`](../patches/0002-hid-over-spi.patch) | Adds a HID-over-SPI transport driver. | The patch header attributes the implementation to the Surface Duo OSS kernel; verify compatibility and provenance before carrying it to another kernel. |

## Outgoing patch series

### DWC3 USB PHY resume

These three patches form one series and should be considered together:

1. [`0001-dt-bindings-usb-dwc3-document-snps-reinit-phy-on-res.patch`](../patches/outgoing/dwc3-usb/0001-dt-bindings-usb-dwc3-document-snps-reinit-phy-on-res.patch) documents the `snps,reinit-phy-on-resume` property.
2. [`0002-usb-dwc3-add-reinit-phy-on-resume-quirk.patch`](../patches/outgoing/dwc3-usb/0002-usb-dwc3-add-reinit-phy-on-resume-quirk.patch) implements the DWC3 quirk.
3. [`0003-arm64-dts-qcom-x1e80100-microsoft-romulus-add-phy-re.patch`](../patches/outgoing/dwc3-usb/0003-arm64-dts-qcom-x1e80100-microsoft-romulus-add-phy-re.patch) enables it for Romulus.

The series addresses USB2 PHY state loss across deep sleep. Check the target
kernel and patch dependencies before applying it.

### OV02C10 camera

- [`0004-OV02C10-camera-device-tree.patch`](../patches/outgoing/ov02c10/0004-OV02C10-camera-device-tree.patch) adds the camera-related device-tree description.
- [`0005-OV02C10-camera-metadata.patch`](../patches/outgoing/ov02c10/0005-OV02C10-camera-metadata.patch) adds crop metadata support to the OV02C10 driver.

See [config/OV02C10-camera/README.md](../config/OV02C10-camera/README.md) for
the userspace tuning and libcamera notes. These patches are not automatically
applied by any helper script.

## Historical upstreamed patch

[`0003-fix-duplicate-battery.patch`](../patches/upstreamed/0003-fix-duplicate-battery.patch)
removes duplicate battery software nodes from the Surface Aggregator registry.
It is retained as a record of the change, not as an instruction to apply it.

## Maintaining this index

When adding a patch, record its target kernel/tree, purpose, dependencies, and
current lifecycle status. Move it between lifecycle folders only when that
status is confirmed; keep references in the README and feature guides current.
