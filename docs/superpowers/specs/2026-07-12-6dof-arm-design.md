# 6DOF Robot Arm Controller — Design

**Date:** 2026-07-12
**Status:** Approved

## Overview

Firmware and host software to control a hand-built 6DOF robot arm using an
Elegoo ESP32 board and a PCA9685 I2C PWM driver with six MG996R servos. The
system is ROS2-native from day one: the ESP32 runs micro-ROS and appears as a
real ROS2 node, so the arm plugs directly into the ROS2 ecosystem (Foxglove
now; Strands-Robots, MoveIt, cameras and sensors later). Documentation is
published as a GitHub Pages site. Custom 3D-printed enclosures mount the
boards to the arm's existing metal brackets.

## Goals

1. Drive all six joints smoothly and safely over WiFi via standard ROS2 topics.
2. Browser-based control UI (Foxglove) with sliders and live joint-state plots.
3. Clean migration path: Docker on macOS now → Raspberry Pi host later,
   changing only one IP address in firmware config.
4. Public docs site: architecture, install guide, parts list, design
   decisions, print files, photo gallery.
5. Foundation for later work: camera, sensor kit, Strands-Robots/MoveIt.

## Non-Goals (for now)

- Inverse kinematics / MoveIt integration (phase 2).
- Camera-based perception (phase 2; calibration webcam plumbing is phase 1).
- Custom web UI beyond Foxglove (add rosbridge + static page later if wanted).
- True joint position feedback (MG996R has none; we report commanded angles).

## Hardware

| Item | Detail | Status |
|---|---|---|
| MCU | Elegoo ESP32 (WiFi, USB-C), Arduino IDE compatible, 3.3V logic | owned |
| Servo driver | PCA9685 16-ch I2C PWM board, addr 0x40 | owned |
| Servos | 6× MG996R (4.8–7.2V; ~1A moving, 2.5A+ stall each) | owned |
| Servo power | 12V/10A car supply → 12–40V-input to 6V/10A 60W buck-boost module | converter ordered |
| Rail capacitor | ≥1000µF across 6V servo rail (stall-spike absorber) — 1000µF already fitted onboard the PCA9685 | owned |
| Host | macOS + Docker now; spare Raspberry Pi later | owned |
| Webcam | Mac camera or USB cam for calibration observation | owned |
| Printer | Bambu Lab P2S; PLA for fit prototypes, PETG for final mounts | owned |

**Power rules:**
- 12V supply NEVER connects to servos or PCA9685 V+ directly (destroys MG996Rs).
- Servo rail: converter 6V output → PCA9685 V+ terminal block (onboard 1000µF
  cap absorbs stall spikes; keep converter→board wires short and thick).
- ESP32 powered by USB-C; grounds common with servo rail.
- USB-only power is limited to single-servo bench testing.

## Architecture

```
┌────────────── Mac (now) / Raspberry Pi (later) ────────────────┐
│  Docker: ROS2 Jazzy                                            │
│  ├── micro-ROS Agent  (UDP :8888 ↔ ESP32 over WiFi)            │
│  ├── Foxglove Bridge  (WebSocket :8765 → browser UI)           │
│  └── (later) Strands-Robots / MoveIt / camera nodes            │
└────────────────────────────────────────────────────────────────┘
                        │ WiFi (XRCE-DDS over UDP)
┌──────────── ESP32 (Arduino IDE + micro_ros_arduino) ───────────┐
│  micro-ROS node "arm_controller"                               │
│  ├── sub: /arm/joint_commands                                  │
│  ├── pub: /joint_states @ 20Hz, /arm/status @ 1Hz              │
│  ├── trajectory engine (trapezoidal velocity per joint)        │
│  └── watchdog: agent link lost >2s → hold position, reconnect  │
└────────────────────────────────────────────────────────────────┘
                        │ I2C @ 3.3V (addr 0x40)
              PCA9685 ── 6× MG996R  (V+ from 6V/10A converter)
```

### ROS2 interface (standard messages only)

| Topic | Type | Dir | Rate | Purpose |
|---|---|---|---|---|
| `/joint_states` | `sensor_msgs/JointState` | pub | 20Hz | commanded angle per joint, radians, names `joint1..joint6` |
| `/arm/joint_commands` | `sensor_msgs/JointState` | sub | — | target angles; optional per-joint velocity |
| `/arm/status` | `std_msgs/String` (JSON) | pub | 1Hz | uptime, RSSI, agent link, e-stop flag |

Standard names/units mean MoveIt, Strands-Robots, and any ROS2 tool can drive
the arm without translation.

## Firmware Design

**Stack:** Arduino IDE, `micro_ros_arduino` (precompiled ESP32 support),
Adafruit PWM Servo Driver library.

**Modules** (`firmware/arm_controller/`):
- `ArmController.ino` — setup/loop, micro-ROS node/executor wiring, watchdog.
- `config.h` — WiFi credentials, agent IP, joint limits, per-servo calibration.
- `servo_driver.{h,cpp}` — PCA9685 abstraction; radians → PWM µs using
  per-joint `min_us`, `max_us`, `center_offset`, `direction`.
- `trajectory.{h,cpp}` — trapezoidal-velocity interpolation per joint with
  configurable max velocity/acceleration.

**Control behavior:**
- 50Hz servo update loop, decoupled from ROS message arrival.
- New targets replan smoothly from current interpolated position (no snapping).
- Software joint limits clamp every command before execution.
- Servos idle (no pulses) until the first valid command — no lurch on boot.
- On agent-link loss >2s: hold last position (never go limp — arm would fall),
  then auto-reconnect and re-register.

**Testing:** trajectory math and radian→µs mapping are pure functions with
host-side C++ unit tests (no hardware). Hardware verified via the scripted
bring-up checklist in the docs.

## Host Setup

`host/docker-compose.yml` with two services (ROS2 Jazzy images):
1. `micro-ros-agent` — UDP :8888.
2. `foxglove-bridge` — WebSocket :8765; repo ships `host/foxglove/arm-layout.json`
   with joint sliders + state plots.

Identical compose file runs on the Pi later; migration = install Docker,
`docker compose up`, update agent IP in `config.h`.

`host/calibration/` — Python script (ROS2 + OpenCV) that sweeps a joint while
capturing webcam frames, for visual verification of actual vs. commanded
motion during calibration. Reused later as the base for camera/perception work.

## 3D-Printed Mounts

- Parametric OpenSCAD sources in `hardware/openscad/`, exported STLs in
  `hardware/stl/`.
- Enclosures for ESP32 and PCA9685 screw onto the arm's existing metal
  brackets; bracket hole spacing to be measured before design (open item).
- PLA for fit-check prototypes; PETG (4+ perimeters, ~30% infill) for finals.
- Print settings and assembly documented on the docs site.

## Documentation Site

- **Tooling:** ProperDocs + MaterialX (maintained continuations of MkDocs +
  mkdocs-material; drop-in compatible ecosystem, Mermaid support).
- **Deploy:** GitHub Actions workflow → GitHub Pages on every push to main.
  Publishing requires a GitHub repo; user confirms before anything is pushed.
- **Pages:** index/overview, architecture, parts list (BOM with links/prices),
  install guide (hardware → firmware → host → first motion), design decisions
  (ADR-style), 3D printing, photo gallery (photos added as build progresses).

## Repository Layout

```
arduino-arm/
├── firmware/arm_controller/      # .ino + modules above
├── host/
│   ├── docker-compose.yml
│   ├── foxglove/arm-layout.json
│   └── calibration/              # webcam-assisted calibration script
├── hardware/
│   ├── openscad/  ├── stl/  └── wiring.md
├── docs/                         # ProperDocs site content
└── .github/workflows/docs.yml
```

## Design Decisions (ADR summary)

1. **ESP32 over Uno R3** — WiFi control, 240MHz dual core, RAM headroom for
   interpolation; Arduino-IDE compatible.
2. **micro-ROS over custom protocol + bridge** — ROS2-native from day one to
   stay aligned with the ROS2 ecosystem (user priority), at the cost of firmware
   complexity and requiring the agent to be running.
3. **Foxglove over ESP32-served web UI** — zero UI code on the MCU, native
   ROS2 topic access, plots/teleop/camera panels for free; custom UI can be
   added host-side later without firmware changes.
4. **Hold-position on link loss over go-limp** — a limp arm falls; holding is
   the safe failure mode for a tabletop arm.
5. **Commanded-position joint states** — MG996R has no feedback; reporting
   commanded angles is standard practice for this hardware class.
6. **ProperDocs + MaterialX over MkDocs** — original MkDocs stalled; these are
   the community-maintained successors, drop-in compatible.
7. **12V/10A supply + 6V converter over dedicated 6V supply** — reuses owned
   hardware; converter input range (12–40V) verified to cover the 12V supply.

## Bring-Up Sequence (implementation order)

1. Repo scaffold, docs site skeleton, CI deploy. *(GitHub publish: ask first)*
2. Firmware: micro-ROS registration over WiFi; `/joint_states` visible via
   `ros2 topic echo`; single servo sweep on USB power.
3. Joint-by-joint calibration (webcam-assisted), values into `config.h`.
4. Full arm on converter power; verify software limits; slow poses via Foxglove.
5. First choreographed pose sequence; photos → gallery.
6. Mount design → PLA fit check → PETG finals.

## Open Items

- Measure bracket hole spacing before mount design.
- Confirm exact Elegoo ESP32 module (pinout varies slightly) at flash time.
- GitHub repo name + public/private decision before first push.
- WiFi SSID/credentials supplied locally at flash time (never committed;
  `config.h` is gitignored with a committed `config.example.h`).
