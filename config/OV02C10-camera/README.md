1. Tuning file (color correction)

Drop `ov02c10.yaml` into the Simple IPA tuning directory:

```bash
sudo cp ov02c10.yaml /usr/share/libcamera/ipa/simple/
```

2. Patch Libcamera (sensor gain helper)

The IPA needs a `CameraSensorHelper` entry so it understands the sensor's real gain units instead of raw register codes. - this is going to be part of a libcamera upstream patch series I'm working on.

Build dependencies:

```bash
sudo apt build-dep libcamera
sudo apt install meson ninja-build
```

Apply and build:

```bash
cd /path/to/libcamera-v0.7.0
patch -p1 < ov02c10-ipa-changes.patch
meson setup build
ninja -C build src/ipa/simple/ipa_soft_simple.so
```

Install:

```bash
sudo cp build/src/ipa/simple/ipa_soft_simple.so \
    /usr/lib/aarch64-linux-gnu/libcamera/ipa/ipa_soft_simple.so
```

CPU debayer workaround (recommended)

The GPU debayer (default) gets a garbage white frame on frame 0 due to an IPC timing race in the Simple pipeline — `setIspParams` arrives asynchronously, so the GPU shader reads uninitialized shared-memory params on the first frame. CPU mode avoids this entirely since `DebayerCpu` reads params synchronously - probably not the cleanest solution but this works for now.

```bash
mkdir -p ~/.config/libcamera
cat > ~/.config/libcamera/configuration.yaml << 'EOF'
software_isp:
  mode: cpu
EOF
```

Ideally long term fix is for the Agc and Adjust algorithms to read these values from the tuning file — then no source changes are needed per camera.
