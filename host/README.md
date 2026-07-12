# Host stack — micro-ROS agent + Foxglove bridge

Everything the arm needs on the host side runs from one compose file:

```
host/
├── docker-compose.yml        # the whole stack: agent (UDP :8888) + bridge (WS :8765)
├── foxglove-bridge/          # tiny Dockerfile (ros:jazzy-ros-base + ros-jazzy-foxglove-bridge)
├── foxglove/                 # importable Foxglove layout + instructions
└── calibration/              # webcam-assisted joint calibration tooling
```

Works unchanged on Docker Desktop (macOS, incl. Apple Silicon) today and on
a 64-bit Raspberry Pi later — both images are multi-arch (amd64 + arm64).

## Prerequisites

- Docker Desktop (macOS) or Docker Engine + compose plugin (Raspberry Pi OS
  64-bit / Ubuntu). No local ROS2 install needed.

## Run it

```bash
cd host
docker compose up          # first run builds the foxglove-bridge image
```

You should see the micro-ROS agent start listening on UDP 8888 and the
bridge report `WebSocket server listening on 0.0.0.0:8765`. Once the ESP32
boots and reaches the agent, the agent log shows a session being created.

Stop with Ctrl-C, or `docker compose up -d` / `docker compose down` for
detached use.

## Find the Mac's LAN IP (for the ESP32 `config.h`)

The firmware needs the agent's address (`AGENT_IP` in
`firmware/arm_controller/config.h`). Use the machine's LAN IP, not
localhost:

```bash
ipconfig getifaddr en0     # Wi-Fi on most Macs
ipconfig getifaddr en1     # try this if en0 is empty (wired/older Macs)
```

or System Settings → Wi-Fi → Details… → IP address. On the Raspberry Pi
later: `hostname -I`. Consider a DHCP reservation for the host so the IP in
`config.h` doesn't rot.

The ESP32 sends UDP to `<that IP>:8888`; Docker publishes the port into the
agent container.

## Smoke tests (ros2 CLI)

There's no ROS2 on the Mac itself, so run the CLI inside the bridge
container (its entrypoint doesn't auto-source for `exec`, hence the
`source`):

```bash
cd host

# 1. Topics visible? Expect /joint_states, /arm/status (+ defaults) once the
#    ESP32 is up:
docker compose exec foxglove-bridge bash -c \
  "source /opt/ros/jazzy/setup.bash && ros2 topic list"

# 2. Live joint states streaming at ~20 Hz:
docker compose exec foxglove-bridge bash -c \
  "source /opt/ros/jazzy/setup.bash && ros2 topic echo /joint_states"

# 3. Arm status (1 Hz JSON heartbeat):
docker compose exec foxglove-bridge bash -c \
  "source /opt/ros/jazzy/setup.bash && ros2 topic echo /arm/status"

# 4. Move joint1 to 0.5 rad (FIRST MOTION — be ready to cut servo power):
docker compose exec foxglove-bridge bash -c \
  'source /opt/ros/jazzy/setup.bash && ros2 topic pub --once /arm/joint_commands sensor_msgs/msg/JointState "{name: [joint1], position: [0.5]}"'

# ...and back to center:
docker compose exec foxglove-bridge bash -c \
  'source /opt/ros/jazzy/setup.bash && ros2 topic pub --once /arm/joint_commands sensor_msgs/msg/JointState "{name: [joint1], position: [0.0]}"'
```

## Foxglove UI

Open the Foxglove app (or <https://app.foxglove.dev>) → **Open connection**
→ **Foxglove WebSocket** → `ws://localhost:8765`, then import
`foxglove/arm-layout.json`. Details and manual publish-panel setup:
[foxglove/README.md](foxglove/README.md).

## Calibration

Joint-by-joint webcam-assisted calibration (sweep runs in the container,
frame capture runs on the Mac): [calibration/README.md](calibration/README.md).

## Migrating to the Raspberry Pi later

1. Install Docker Engine + compose plugin on a 64-bit OS.
2. Copy `host/` across, `docker compose up`.
3. Update `AGENT_IP` in the firmware `config.h` to the Pi's IP; reflash.
4. Optional (Linux only): switch both services to `network_mode: host` and
   delete the `ports:` blocks — lets ROS2 nodes running directly on the Pi
   (MoveIt, camera nodes) discover the topics without exec-ing into a
   container.

## Troubleshooting

- **Agent shows no session** — ESP32 and host must be on the same
  LAN/subnet; check `AGENT_IP`/port in `config.h`, and watch verbose agent
  logs by changing the compose command to `udp4 --port 8888 -v6`.
- **Topics visible in `ros2 topic list` but Foxglove shows nothing** —
  confirm the browser/app is connected to `ws://<host>:8765` (connection
  indicator top-left), and that both containers are on the same compose
  network (they are, by default).
- **`ros2 topic list` shows only defaults** — the ESP32 hasn't registered;
  see the agent log. The firmware retries automatically (watchdog), so
  power-cycling the ESP32 after the stack is up is the quickest reset.
- **Firewall prompt on macOS** — allow Docker to accept incoming
  connections, or the ESP32's UDP packets never reach the agent.
