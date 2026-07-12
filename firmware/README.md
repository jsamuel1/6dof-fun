# Arm Controller Firmware (ESP32 + micro-ROS)

Firmware for the 6DOF arm's Elegoo ESP32. It runs a micro-ROS node named
`arm_controller` over WiFi (UDP, XRCE-DDS) and drives six MG996R servos
through a PCA9685 I2C PWM board.

| Topic | Type | Direction | Rate |
|---|---|---|---|
| `/joint_states` | `sensor_msgs/JointState` | publish | 20 Hz |
| `/arm/status` | `std_msgs/String` (JSON) | publish | 1 Hz |
| `/arm/joint_commands` | `sensor_msgs/JointState` | subscribe | — |

Layout:

- `arm_controller/` — the Arduino sketch and its modules
- `test/` — host-side unit tests for the pure math modules (no hardware
  needed): `bash test/run_tests.sh`

## Arduino IDE setup

Tested with Arduino IDE 2.x.

1. **Install ESP32 board support.**
   - Open *File → Preferences* and add this URL to *Additional boards manager
     URLs*:
     `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
   - Open *Tools → Board → Boards Manager*, search for **esp32**, and install
     the **esp32 by Espressif Systems** package.

2. **Install micro_ros_arduino (Jazzy).**
   - Download the Jazzy release ZIP from
     <https://github.com/micro-ROS/micro_ros_arduino/releases> (pick the
     release tagged for **Jazzy**).
   - In the IDE: *Sketch → Include Library → Add .ZIP Library…* and select
     the downloaded ZIP. (This library ships precompiled micro-ROS support
     for ESP32 — no colcon build needed.)

3. **Install the servo driver library.**
   - *Tools → Manage Libraries…*, search for **Adafruit PWM Servo Driver
     Library**, install it (accept the suggested dependencies).

4. **Select the board.**
   - *Tools → Board → esp32 → ESP32 Dev Module*.
   - Leave the default settings (240 MHz, 4MB flash) unless your Elegoo
     variant documents otherwise.

5. **Create your local config.**

   ```sh
   cp arm_controller/config.example.h arm_controller/config.h
   ```

   Edit `arm_controller/config.h`:
   - `WIFI_SSID` / `WIFI_PASSWORD` — a **2.4 GHz** network (ESP32 has no
     5 GHz radio).
   - `AGENT_IP` — the LAN IP of the machine running the micro-ROS agent
     (`host/docker-compose.yml`). Port stays `8888` unless you changed the
     compose file.
   - Leave the joint calibration table at its defaults for first bring-up;
     refine it during calibration.

   `config.h` is gitignored — real credentials never leave your machine.

6. **Flash.**
   - Connect the ESP32 via USB-C, pick its serial port under *Tools → Port*
     (macOS: `/dev/cu.usbserial-*` or `/dev/cu.wchusbserial-*`; if no port
     appears you may need the CP210x or CH34x USB-serial driver for your
     board revision).
   - Open `arm_controller/arm_controller.ino` and click **Upload**. Some
     boards need the **BOOT** button held when the IDE prints
     `Connecting...`.

## Serial-monitor smoke test

No servos or PCA9685 required — USB power only.

1. Start the agent on the host: `docker compose up` in `host/` (the
   `micro-ros-agent` service listens on UDP 8888).
2. Open *Tools → Serial Monitor* at **115200 baud** and press the ESP32's
   **EN/RST** button. Expected boot sequence:

   ```
   [arm] 6DOF arm controller booting
   [arm] WARNING: PCA9685 not responding on I2C ... (normal with no board attached)
   [arm] joining WiFi "your-ssid" ...
   [arm] WiFi up, IP 192.168.x.x, agent 192.168.x.x:8888
   [arm] agent available, creating entities
   [arm] connected to agent
   ```

3. From any ROS2 Jazzy shell (e.g. `docker compose exec micro-ros-agent
   bash`), verify the node and topics:

   ```sh
   ros2 node list                 # -> /arm_controller
   ros2 topic hz /joint_states    # -> ~20 Hz
   ros2 topic echo /arm/status    # JSON: uptime_s, rssi, agent_connected, estop
   ```

4. Watchdog check: stop the agent (`docker compose stop micro-ros-agent`).
   Within ~2 s the serial monitor prints
   `[arm] agent link lost >2s: holding position, reconnecting`, and after
   `docker compose start micro-ros-agent` it reconnects by itself.

5. Single-servo motion check (PCA9685 attached, ONE servo on channel 0, USB
   power is fine for one unloaded servo):

   ```sh
   ros2 topic pub --once /arm/joint_commands sensor_msgs/msg/JointState \
     "{name: [joint1], position: [0.0]}"
   ros2 topic pub --once /arm/joint_commands sensor_msgs/msg/JointState \
     "{name: [joint1], position: [0.5], velocity: [0.5]}"
   ```

   The first command arms the joint at center; the second sweeps it ~29°
   at 0.5 rad/s. `ros2 topic echo /joint_states` shows the interpolated
   motion.

## Behavior notes

- **No pulses until commanded.** Every PCA9685 channel is held OFF from boot
  until the first valid command names that joint, so the arm never lurches
  on power-up. The *first* command for a joint is adopted as the current
  position and the servo moves there at its own uncontrolled speed — make
  the first command close to the arm's physical pose (center, `0.0`, if you
  assembled the arm centered).
- **Hold on link loss.** If the agent link drops for more than 2 s, the
  firmware keeps emitting the last pulse train (the arm holds, never goes
  limp) while it destroys and re-creates its micro-ROS entities and
  reconnects automatically.
- **Limits always apply.** Commands are clamped to each joint's
  `min_rad`/`max_rad`, and motion respects `max_vel_rad_s` /
  `max_acc_rad_s2` via a trapezoidal velocity profile. A command's
  `velocity[]` entry (rad/s) lowers — never raises — that move's speed cap.
- **Commanded, not measured.** MG996R servos have no feedback;
  `/joint_states` reports the commanded (interpolated) angle. Joints not yet
  commanded report `0.0`.

## Host-side unit tests

The calibration math (`joint_mapping.h`) and trajectory generator
(`trajectory.{h,cpp}`) are Arduino-free and tested on the host:

```sh
bash test/run_tests.sh
```

Requires only `clang++` (Xcode command line tools on macOS). CI-friendly:
exits nonzero on any failure.
