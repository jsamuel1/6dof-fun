# Architecture

The system is three layers: a browser UI, a Docker host running ROS2 Jazzy,
and the ESP32 firmware. The ESP32 is a real ROS2 node — the host's micro-ROS
agent is transport plumbing, not a protocol translator.

## System diagram

```mermaid
flowchart TD
    browser["Browser — Foxglove UI<br/>(sliders + joint-state plots)"]

    subgraph host["Mac (now) / Raspberry Pi (later) — Docker, ROS2 Jazzy"]
        agent["micro-ROS Agent<br/>UDP :8888"]
        bridge["Foxglove Bridge<br/>WebSocket :8765"]
        future["(later) Strands-Robots /<br/>MoveIt / camera nodes"]
    end

    subgraph esp32["ESP32 — Arduino IDE + micro_ros_arduino"]
        node["micro-ROS node 'arm_controller'<br/>sub /arm/joint_commands<br/>pub /joint_states @ 20Hz<br/>pub /arm/status @ 1Hz"]
        traj["Trajectory engine<br/>trapezoidal velocity per joint, 50Hz"]
        wdog["Watchdog<br/>agent link lost >2s → hold position, reconnect"]
    end

    pca["PCA9685 16-ch PWM driver<br/>I2C addr 0x40, onboard 1000µF cap"]
    servos["6× MG996R servos"]
    psu["12V/10A supply"]
    buck["12–40V → 6V/10A<br/>buck-boost converter"]

    browser <-->|"WebSocket :8765"| bridge
    agent <-->|"WiFi — XRCE-DDS over UDP :8888"| node
    node --> traj
    wdog -.-> traj
    traj -->|"I2C @ 3.3V"| pca
    pca -->|"PWM"| servos
    psu --> buck
    buck -->|"6V to V+ terminal"| pca
```

## ROS2 interface

Standard messages only — MoveIt, Strands-Robots, and any ROS2 tool can drive
the arm without translation. Joint names are `joint1`..`joint6`, angles in
radians.

| Topic | Type | Dir | Rate | Purpose |
|---|---|---|---|---|
| `/joint_states` | `sensor_msgs/JointState` | pub | 20Hz | Commanded angle per joint (radians). The MG996R has no feedback, so these are commanded, not measured, positions. |
| `/arm/joint_commands` | `sensor_msgs/JointState` | sub | — | Target angles; optional per-joint velocity. |
| `/arm/status` | `std_msgs/String` (JSON) | pub | 1Hz | Uptime, WiFi RSSI, agent link state, e-stop flag. |

## Firmware modules

All firmware lives in `firmware/arm_controller/`:

| File | Responsibility |
|---|---|
| `ArmController.ino` | `setup()`/`loop()`, micro-ROS node and executor wiring, the agent-link watchdog. |
| `config.h` | WiFi credentials, agent IP, joint limits, per-servo calibration. Gitignored; copy from the committed `config.example.h`. |
| `servo_driver.{h,cpp}` | PCA9685 abstraction. Converts radians to PWM microseconds using per-joint `min_us`, `max_us`, `center_offset`, and `direction`. |
| `trajectory.{h,cpp}` | Trapezoidal-velocity interpolation per joint with configurable maximum velocity and acceleration. |

## Control behavior

- **50Hz servo update loop**, decoupled from ROS message arrival — motion stays
  smooth regardless of network jitter.
- **Smooth replanning** — a new target replans from the current interpolated
  position; the arm never snaps.
- **Software joint limits** clamp every command before execution.
- **No lurch on boot** — servos receive no pulses until the first valid command.
- **Link-loss safety** — if the agent link is lost for more than 2 seconds the
  arm holds its last position (a limp arm would fall), then automatically
  reconnects and re-registers.

## Testing strategy

Trajectory math and the radian→microsecond mapping are pure functions with
host-side C++ unit tests — no hardware required. Hardware behavior is verified
with the scripted bring-up checklist in
[Install → First Motion](install/4-first-motion.md).
