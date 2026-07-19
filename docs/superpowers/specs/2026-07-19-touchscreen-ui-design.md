# Touchscreen Jog + Calibrate UI — Design

Date: 2026-07-19
Status: approved approach (A) — custom web UI + rosbridge, Chromium kiosk
Target: Magedok T101F (1540×720, Elan touch) attached to `armdell`
(Ubuntu Server 24.04 ROS2 host, stack in `host/pi/docker-compose.yml`)

## Goal

A touch-first control panel on the arm's bench screen for the work we do
most right now: jogging joints, re-indexing horns, and running the
`/arm/cal` microsecond calibration — with the camera view beside it and
an e-stop you can slap. The same URL must work from any browser on the
LAN (Mac included); the kiosk is just one client.

## Non-goals (v1)

- Saved poses, trajectory playback, kinematics/IK, speech, auth.
- Multi-user arbitration (last writer wins — single-operator bench tool).
- Replacing Foxglove for plotting/inspection on the Mac.

## Architecture

```
Magedok (touch) ── cage + Chromium kiosk (systemd, boots fullscreen)
                        │  http://localhost:8088
                        ▼
   arm-web (nginx:alpine, :8088) ── serves host/web/ static files
   arm-rosbridge (:9090 ws)      ── roslibjs topics pub/sub
   arm-web-video (:8080 http)    ── MJPEG stream of /image_raw
                        │
              (existing) arm-micro-ros-agent ◄── UDP 8888 ── ESP32
                         arm-camera, arm-foxglove-bridge unchanged
```

Three additions to `host/pi/docker-compose.yml`, all `network_mode: host`
like the rest of the stack:

| Service | Image | Port | Role |
|---|---|---|---|
| `arm-rosbridge` | `ros:jazzy-ros-core` + `ros-jazzy-rosbridge-server` (small Dockerfile) | 9090/ws | JSON⇄DDS bridge for the page |
| `arm-web-video` | same base + `ros-jazzy-web-video-server` (can share the Dockerfile/image with rosbridge) | 8080 | `GET /stream?topic=/image_raw&type=mjpeg` |
| `arm-web` | `nginx:alpine`, bind-mount `host/web/` | 8088 | static page |

## Web page (`host/web/`)

Single static page, no build tooling: `index.html` + `app.js` +
`style.css`, with `roslib.min.js` vendored into `host/web/vendor/`
(no CDN — the bench must work without internet).

Layout, 1540×720 landscape, dark theme, three columns:

1. **Left (~500 px): camera** — `<img>` of the MJPEG stream. Tap to
   cycle 90° rotation (CSS transform; camera mounting is uncontrolled).
2. **Middle (~740 px): six joint rows** — each row:
   `◀◀  ◀  [joint1  −12.3°]  ▶  ▶▶`
   - ◀/▶ = 2° step, ◀◀/▶▶ = 10° step. Discrete taps only — no sliders
     (a stray swipe must never command a large motion).
   - Steps apply to the *last commanded/known position* from
     `/joint_states` and publish a full `sensor_msgs/JointState` to
     `/arm/joint_commands` (single named joint in the message).
   - Center readout shows live position from `/joint_states`; row is
     visually dimmed until that joint is armed (per `/arm/status`).
3. **Right (~300 px): safety + cal + status**
   - **STOP**: ≥120 px tall, red; publishes `"x"` to `/arm/cal`
     (firmware e-stop) — no confirmation dialog.
   - **Cal mode toggle**: when on, the *selected* joint row swaps its
     jog buttons for µs nudges publishing to `/arm/cal`:
     `<`(−50) `-`(−10) `[1550 µs]` `+`(+10) `>`(+50), plus `c` (center)
     and channel select `0`–`5` (tap a joint row to select).
   - **Status strip**: agent link state, RSSI, uptime, `cal_ch`/`cal_us`
     (parsed from the `/arm/status` JSON), rosbridge connection state.

Touch details: `<meta name="viewport" ... user-scalable=no>`, buttons
≥ 72 px hit targets, `touch-action: manipulation` (kills double-tap
zoom delay), no hover-dependent affordances.

## Data flow & topics

| Topic | Dir | Type | Use |
|---|---|---|---|
| `/arm/joint_commands` | UI → arm | `sensor_msgs/JointState` | jog targets (radians; UI works in degrees, converts) |
| `/arm/cal` | UI → arm | `std_msgs/String` | single-char cal commands (`0`-`5 - + < > c x`), same alphabet as the serial diag console |
| `/joint_states` | arm → UI | `sensor_msgs/JointState` | live readouts (best-effort QoS; rosbridge must subscribe best-effort) |
| `/arm/status` | arm → UI | `std_msgs/String` (JSON) | link/RSSI/estop/cal state at 1 Hz |
| `/image_raw` | camera → UI | via web_video_server MJPEG | not a rosbridge topic — plain `<img>` |

## Error handling

- **rosbridge socket lost**: all command buttons disable, banner shows
  "reconnecting…", auto-retry with backoff. Never queue taps.
- **`/arm/status` stale > 3 s**: agent indicator goes red — commands
  stay enabled (rosbridge may be fine while the ESP32 rebooted; the
  firmware ignores commands it can't act on).
- **Jog clamping**: UI clamps to the same ±90° soft limits as
  `config.h`; firmware clamps again regardless (UI limits are cosmetic,
  firmware limits are authoritative).
- **Camera stream dead**: `<img>` `onerror` → placeholder + retry
  button; never blocks the control column.

## Kiosk on armdell (outside Docker)

- `apt install cage`; Chromium via snap (Ubuntu's only packaging).
- `kiosk.service` (systemd, `After=docker.service`): runs
  `cage -- chromium --kiosk --noerrdialogs --disable-pinch http://localhost:8088`
  as user `jsamuel` on tty1; `Restart=always`.
- The Magedok is HDMI-A-1 @ native 1540×720 (EDID read works on this
  box — no mode forcing needed). Elan touch works as a standard input
  device under Wayland/cage.
- Laptop's built-in eDP panel: lid is typically closed (logind ignores
  it); if open, cage extends across both — acceptable v1 quirk.

## Testing

1. Compose services up on armdell; open `http://armdell:8088` from the
   Mac: verify status strip, joint rows live-update, STOP publishes.
2. With PCA9685 + one servo wired: jog CH0 ±2°, verify motion + readout.
3. Cal mode: select ch, nudge µs, watch `cal_us` in status strip echo.
4. Kill rosbridge container: buttons disable, banner appears; restart:
   auto-reconnect.
5. Enable kiosk.service, reboot armdell: UI appears on Magedok without
   interaction; touch jog works.

## Risks / notes

- rosbridge + best-effort QoS on `/joint_states` needs an explicit QoS
  override in the subscribe call (roslibjs supports this); otherwise the
  readouts stay empty.
- The 2012-era Dell renders one MJPEG 640×480@15 stream + a static page
  easily; no GPU concerns under cage.
- Chromium-snap under cage on a headless-boot server is the fiddliest
  piece (seat/permissions); if it fights back, fallback is
  `chromium --kiosk` under a minimal X + `xinit` instead of Wayland.
