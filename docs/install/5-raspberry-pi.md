# Install 5/4 (bonus) — Raspberry Pi Host + Camera

Promote a Raspberry Pi 4B to the arm's permanent ROS2 brain: micro-ROS
agent, Foxglove bridge, and a camera publisher — replacing the Docker
Desktop stack on the Mac. On Linux the containers use **real host
networking**, so ROS2/DDS works across the whole LAN with none of the
Docker-Desktop workarounds from [Host Software](3-host.md).

```
Raspberry Pi 4B (arm64, network_mode: host)
├── micro-ROS agent :8888/udp   ← ESP32 connects here
├── foxglove-bridge :8765       ← Foxglove on any machine
└── camera → /image_raw/compressed
```

## 1. Prepare the Pi

1. Flash **Raspberry Pi OS Lite (64-bit)** with Raspberry Pi Imager —
   the 64-bit part is required (the ROS2 images are arm64). In the
   Imager's settings gear: set hostname (`armpi`), enable SSH, add your
   WiFi credentials.
2. Boot, then give the Pi a **DHCP reservation** in your router — the
   ESP32 firmware bakes the agent IP in, so it must not drift.
3. SSH in and install Docker:

   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER   # log out/in afterwards
   ```

## 2. Start the stack

```bash
git clone https://github.com/jsamuel1/6dof-fun.git
cd 6dof-fun/host/pi
docker compose up -d --build
```

Camera default is a **USB webcam** on `/dev/video0`. For a ribbon-cable
Pi Camera Module, follow the libcamera note in `host/pi/camera/Dockerfile`.

## 3. Repoint the ESP32

1. Edit `firmware/arm_controller/config.h`: `AGENT_IP` → the Pi's IP.
2. Reflash over USB (see [Firmware](2-firmware.md)). This is the only
   step that still needs a cable, and only once.

## 4. Verify

- `docker compose exec foxglove-bridge bash -c "source /opt/ros/jazzy/setup.bash && ros2 topic list"`
  → expect `/joint_states`, `/arm/status`, `/arm/cal`, `/image_raw/compressed`
- Foxglove (Mac or anywhere): connect to `ws://<pi-ip>:8765`, add an
  **Image** panel on `/image_raw/compressed` — live video of the arm.
- Point the camera at the arm and it doubles as the
  [calibration](4-first-motion.md) observer.

## Notes

- The Mac stack (`host/docker-compose.yml`) still works for bench use;
  run one or the other, not both (two agents on one LAN port is chaos —
  they'd both answer the ESP32).
- Pi CPU load at 640×480@15fps MJPEG is modest; raise resolution in
  `host/pi/docker-compose.yml` once the pipeline is proven.
