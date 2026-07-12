# Install 2/4 — Firmware

The firmware lives in `firmware/arm_controller/` and builds in the standard
Arduino IDE — no special toolchain.

## 1. Arduino IDE + ESP32 board support

1. Install the [Arduino IDE](https://www.arduino.cc/en/software) (2.x).
2. Add the ESP32 board core: **File → Preferences → Additional boards manager
   URLs** and add:
   ```
   https://espressif.github.io/arduino-esp32/package_esp32_index.json
   ```
3. **Tools → Board → Boards Manager**, search "esp32", install **esp32 by
   Espressif Systems**.
4. Select your board under **Tools → Board → esp32** (a generic "ESP32 Dev
   Module" works for the Elegoo board; confirm the exact module of your Elegoo
   ESP32 at flash time — pinouts vary slightly between revisions).

## 2. Libraries

Two libraries, installed two different ways:

- **micro_ros_arduino (Jazzy)** — installed as a ZIP, *not* from the Library
  Manager. Download the **Jazzy** release ZIP from
  [micro-ROS/micro_ros_arduino releases](https://github.com/micro-ROS/micro_ros_arduino/releases)
  (pick the release tagged for ROS2 Jazzy — it ships precompiled ESP32
  support), then **Sketch → Include Library → Add .ZIP Library…** and select
  the downloaded file.
- **Adafruit PWM Servo Driver Library** — from the Library Manager:
  **Tools → Manage Libraries…**, search "Adafruit PWM Servo Driver", install
  (accept the dependency prompt).

## 3. Configuration

WiFi credentials and the agent IP are local-only — `config.h` is gitignored
and never committed.

```bash
cd firmware/arm_controller
cp config.example.h config.h
```

Edit `config.h` and set:

| Setting | Value |
|---|---|
| WiFi SSID / password | your network credentials |
| Agent IP | the LAN IP of the machine that will run Docker (your Mac for now; when you later migrate to a Raspberry Pi, this one line is the only firmware change) |
| Agent port | `8888` (default, matches `host/docker-compose.yml`) |
| Joint limits / servo calibration | leave the example defaults for now — you will fill in real values during [calibration](4-first-motion.md) |

## 4. Flash

1. Connect the ESP32 over USB-C and pick the serial port under **Tools → Port**.
2. Open `firmware/arm_controller/arm_controller.ino` and click **Upload**.
3. Open **Tools → Serial Monitor** (115200 baud). You should see the board
   join WiFi and start trying to reach the micro-ROS agent. It will retry
   until the agent is up — that's expected; the agent comes next.

!!! note "Servos stay silent"
    By design the firmware sends no servo pulses until the first valid
    command arrives, so nothing moves (or lurches) at boot.

## Troubleshooting

!!! warning "Apple Silicon Macs need Rosetta 2"
    Arduino's sketch preprocessor bundles an Intel-only `ctags` binary. On an
    Apple Silicon Mac without Rosetta the build fails with
    `bad CPU type in executable`. Fix:

    ```bash
    softwareupdate --install-rosetta --agree-to-license
    ```

    Do **not** substitute Homebrew's ctags — it lacks Arduino's `returntype`
    patch and produces `ISO C++ forbids declaration ... with no type` errors.
    If you tried that first, recompile once with `--clean` (or Sketch →
    Verify after restarting the IDE) to purge the poisoned build cache.

Next: [Install 3/4 — Host Software](3-host.md).
