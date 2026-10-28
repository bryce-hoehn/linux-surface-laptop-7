# Experimental touchscreen: 15-inch Laptop 7 only

The touchscreen overlay has been tested on one 15-inch Surface Laptop 7
(Romulus15) with the ELLX `7.3.0-rc3+` kernel built from `557ed1f34df3`.
Finger touch and multi-finger gestures worked in that test; pen support is
untested. This is not a generic mainline overlay, and other models, board
revisions, kernels, or firmware may behave differently.

> [!WARNING]
> The hardware configuration remains experimental. Keep recovery media and a
> working normal boot entry available. Test with the separate GRUB entry before
> applying the overlay to the DTB used by normal boot. The permanent install
> also affects recovery entries that use that same DTB.

Tracking issue: [bryce-hoehn/linux-surface-laptop-7#13](https://github.com/bryce-hoehn/linux-surface-laptop-7/issues/13).
If testing on another machine, report its model/SKU and
`grep -H . /sys/bus/hid/devices/*/uevent` output while booted with the overlay.

## What the overlay changes

The published
[Romulus ACPI tables](https://github.com/aarch64-laptops/build/tree/master/misc/microsoft-surface-romulus13_and_15)
describe a `GTCH` SPI touchscreen variant on `SP11` (`spi10`, address
`0xa88000`), with interrupt GPIO 51, reset GPIO 48, and power-enable GPIO 64.
The overlay enables that controller and its GPI DMA provider, adds the quad
data pinmux, and describes the touchscreen separately from the touchpad.

Linux boots this machine with a device tree, so its ACPI tables could not be
read directly in the investigation. The published tables and the Surface Pro
11 HID-over-SPI/QSPI work informed the overlay. Pinmux and QSPI settings follow
the matching kernel definitions and existing touchpad implementation; they
were confirmed only by the test described above.

Important unknowns remain:

- Published tables select different touchscreen variants by board/SKU; this
  machine's own wiring has not been verified against its ACPI tables.
- The installed HID driver uses touchpad-specific reset and power sequencing
  and forces a 20 MHz bus clock. Suitability for this touchscreen, including
  reset timing and report processing, is not fully established.
- No supply voltage is specified because the ACPI GPIO power control does not
  establish one.

## Recommended workflow

Run commands from the repository root.

### 1. Build and validate offline

This changes no boot files or hardware settings:

```bash
./surface.sh touch-check
```

Equivalent direct commands are:

```bash
bash patches/001-touch/test/test-touchscreen.sh --check
bash patches/001-touch/fix/install-touchscreen.sh --check
```

### 2. Try a separate GRUB entry

```bash
./surface.sh touch-test
```

The script requires typing `INSTALL`. It creates
`/boot/romulus15-touchscreen-test.dtb` and `/boot/grub/custom.cfg`, shows the
GRUB menu for 15 seconds, and leaves the normal default entry unchanged.
Select **EXPERIMENTAL: Laptop 7 touchscreen** manually at boot. Save your work
and keep recovery media available; the experimental entry may hang or fail to
boot.

A successful test should enumerate a touchscreen HID device (not just the
`045E:0C77` touchpad), produce real screen-touch input, and leave the keyboard
and touchpad functional. Script validation alone does not demonstrate that
the hardware works.

To remove the separate test entry and test DTB:

```bash
./surface.sh touch-reset
```

This removes the script-managed `/boot/grub/custom.cfg` and its 15-second
timeout override, plus the test DTB. It does not change the normal-boot DTB.
Do not add unrelated entries to that managed `custom.cfg`.

### 3. Optionally install after a successful test

Only after confirming touchscreen operation with the test entry:

```bash
./surface.sh touch-install
```

The script requires typing `APPLY`. It checks that the running kernel, model,
DTB symlinks, original DTB checksum, and rebuilt overlay match the tested
setup. It backs up the original DTB as
`/boot/dtbs/7.3.0-rc3+/qcom/x1e80100-microsoft-romulus15.dtb.before-touchscreen`
and atomically replaces the normal-boot DTB. It does not alter GRUB, reboot,
run `update-grub`, or patch future kernels automatically.

Unlike the separate test entry, this changes the DTB used by normal and
recovery entries that reference that same file. Kernel/package updates may
replace it.

Restore from a working Linux boot:

```bash
./surface.sh touch-restore
```

If Linux cannot boot, use recovery media to mount the root filesystem and
restore the `.dtb.before-touchscreen` backup over the corresponding `.dtb`.

To restore the original DTB if installed and remove the test entry in one step:

```bash
./surface.sh touch-remove-all
```

The original backup is retained. Use `./surface.sh touch-status` to inspect
the normal DTB and test artifacts.

## Manual offline overlay validation

The helper's `touch-check` command is preferred. To compile and merge a
candidate manually without installing it:

```bash
mkdir -p /tmp/romulus15-touchscreen-test
dtc -@ -I dts -O dtb \
  -o /tmp/romulus15-touchscreen-test/touchscreen.dtbo \
  patches/001-touch/fix/romulus15-touchscreen.dtso
fdtoverlay \
  -i /boot/dtbs/7.3.0-rc3+/qcom/x1e80100-microsoft-romulus15.dtb \
  -o /tmp/romulus15-touchscreen-test/romulus15-touchscreen.dtb \
  /tmp/romulus15-touchscreen-test/touchscreen.dtbo
fdtget /tmp/romulus15-touchscreen-test/romulus15-touchscreen.dtb \
  /soc@0/geniqup@ac0000/spi@a88000 status
```

The final command should print `okay`. This confirms the merged device-tree
description only, not hardware operation. Do not copy the resulting DTB over
`/boot` by hand or apply the overlay live.

## References

- [Surface Pro 11 touchscreen investigation](https://github.com/dwhinham/archiso-aarch64-sp11/issues/10)
- [Surface Pro 11 Ubuntu QSPI/HID-over-SPI work](https://github.com/denisix/ubuntu-surface-pro-11)
- [Published Romulus 13/15 ACPI tables](https://github.com/aarch64-laptops/build/tree/master/misc/microsoft-surface-romulus13_and_15)
- [ELLX kernel](https://github.com/ProgrammerIn-wonderland/ELLX-Kernel), which provides the QSPI and `spi_hid` drivers used here
- [Linux device-tree overlay documentation](https://docs.kernel.org/devicetree/overlay-notes.html)
