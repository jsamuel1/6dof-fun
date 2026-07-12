# Install 3/4 — Host Software

The host side is two Docker containers (ROS2 Jazzy images) defined in
`host/docker-compose.yml`:

| Service | Role | Port |
|---|---|---|
| `micro-ros-agent` | Bridges the ESP32's XRCE-DDS traffic into the ROS2 graph | UDP `:8888` |
| `foxglove-bridge` | Exposes ROS2 topics to the Foxglove browser UI | WebSocket `:8765` |

The same compose file runs unchanged on a Raspberry Pi later — migration is
"install Docker, `docker compose up`, change the agent IP in `config.h`".

## 1. Docker Desktop

Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) for
macOS and start it. (On the future Raspberry Pi: install Docker Engine +
compose plugin instead.)

## 2. Start the stack

```bash
cd host
docker compose up
```

First run pulls the ROS2 Jazzy images. Watch the logs: once the agent is
listening on UDP :8888, the ESP32 (flashed in [step 2](2-firmware.md), and on
the same network) connects within a few seconds and you'll see it create the
`arm_controller` session and its topics in the agent log.

Run detached with `docker compose up -d` once you're happy; `docker compose
logs -f` tails the logs.

## 3. Connect Foxglove

1. Open [Foxglove](https://app.foxglove.dev/) in a browser (or the Foxglove
   desktop app).
2. **Open connection… → Foxglove WebSocket** and enter:
   ```
   ws://localhost:8765
   ```
3. Import the shipped layout: **Layout menu → Import from file…** and select
   `host/foxglove/arm-layout.json` from the repo. You get joint sliders
   (publishing `/arm/joint_commands`) and live plots of `/joint_states`.

!!! tip "Connecting from another machine"
    Replace `localhost` with the Docker host's LAN IP. The bridge serves any
    browser on the network.

## 4. Verify

You should now see `/joint_states` updating at 20Hz and `/arm/status` at 1Hz
in Foxglove's topic list. **Don't move anything yet** — the arm is
uncalibrated. Do the smoke tests and calibration next.

Next: [Install 4/4 — First Motion](4-first-motion.md).
