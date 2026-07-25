# Touchscreen Jog + Calibrate UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Touch-first jog/calibrate web panel for the arm, served from armdell's Docker stack, booted fullscreen on the Magedok via a cage+Chromium kiosk.

**Architecture:** Static page (vanilla HTML/CSS/JS + vendored roslibjs) served by nginx; rosbridge_server (ws :9090) bridges the page to DDS; web_video_server (:8080) streams /image_raw as MJPEG. Kiosk is a systemd unit on armdell running cage+Chromium against http://localhost:8088.

**Tech Stack:** roslibjs 1.x, rosbridge_suite (Jazzy), web_video_server (Jazzy), nginx:alpine, cage, Chromium (snap).

**Spec:** `docs/superpowers/specs/2026-07-19-touchscreen-ui-design.md`

## Global Constraints

- No build tooling, no CDN at runtime: roslib.min.js is vendored into `host/web/vendor/`.
- Jog is discrete taps only (2° / 10° steps) — no sliders.
- UI soft-clamps jogs to ±90°; firmware limits remain authoritative.
- `/arm/cal` alphabet is exactly the firmware diag console's: `0`-`5`, `-` (−10 µs), `+` (+10 µs), `<` (−50 µs), `>` (+50 µs), `c` (center), `x` (e-stop).
- Page must work identically at `http://armdell:8088` from any LAN browser; all service URLs derive from `location.hostname`.
- Ports: web 8088, rosbridge 9090, MJPEG 8080 (8765/8888 stay with the existing stack).
- Deviation from spec (recorded): joint rows are not dimmed-until-armed — `/arm/status` carries no per-joint armed flag; v1 shows position readouts unconditionally.

---

### Task 1: Static web app (`host/web/`)

**Files:**
- Create: `host/web/index.html`, `host/web/style.css`, `host/web/app.js`
- Create: `host/web/vendor/roslib.min.js` (vendored: `curl -L https://cdn.jsdelivr.net/npm/roslib@1/build/roslib.min.js`)

**Interfaces:**
- Produces: page expecting `ws://<host>:9090` (rosbridge) and `http://<host>:8080/stream?topic=/image_raw&type=mjpeg`.
- Topics used: pub `sensor_msgs/JointState` → `/arm/joint_commands` (single named joint per message, radians); pub `std_msgs/String` → `/arm/cal`; sub `/joint_states`, `/arm/status`.

- [ ] **Step 1:** Vendor roslib, write the three files (full content in repo — layout: 3-column CSS grid `500px 1fr 300px`, dark theme, `touch-action: manipulation`, buttons ≥72px). Behaviours: reconnect-with-backoff on the rosbridge socket disabling all command buttons + banner while down; `/arm/status` stale >3 s → red agent dot; jog steps applied to last `/joint_states` value, clamped ±90°; cal mode toggle swaps the selected row's jog buttons for µs nudges; STOP always publishes `x` with no confirmation; camera `<img>` with `onerror` retry and tap-to-rotate 90°.
- [ ] **Step 2:** Static sanity: `python3 -m http.server` + browser — page renders, shows "reconnecting" banner (no rosbridge yet), no console errors other than the expected websocket failure.
- [ ] **Step 3:** Commit: `feat: touchscreen jog+calibrate web app`.

### Task 2: Compose services (rosbridge, web_video_server, nginx)

**Files:**
- Create: `host/pi/rosbridge/Dockerfile`
- Modify: `host/pi/docker-compose.yml`

**Interfaces:**
- Consumes: existing DDS domain (default 0) of arm-micro-ros-agent/arm-camera.
- Produces: ws :9090, http :8080 (MJPEG), http :8088 (static page).

- [ ] **Step 1:** Dockerfile: `FROM ros:jazzy-ros-core` + `ros-jazzy-rosbridge-server ros-jazzy-web-video-server` (one image shared by both services).
- [ ] **Step 2:** Compose: `rosbridge` (host network, `ros2 launch rosbridge_server rosbridge_websocket_launch.xml port:=9090`), `web-video` (same image, host network, `ros2 run web_video_server web_video_server --ros-args -p port:=8080`), `web` (nginx:alpine, `ports: 8088:80`, bind-mount `../web` read-only).
- [ ] **Step 3:** Commit + push; on armdell `git pull && docker compose up -d --build`.
- [ ] **Step 4:** Verify from the Mac: `curl -sf http://192.168.2.67:8088` returns the page; `curl -sf "http://192.168.2.67:8080/stream?topic=/image_raw&type=mjpeg"` starts returning MJPEG bytes; rosbridge websocket answers an HTTP Upgrade on :9090.

### Task 3: End-to-end UI verification (browser)

- [ ] **Step 1:** Open `http://192.168.2.67:8088` in the in-app browser: status strip shows agent/RSSI from `/arm/status`; joint readouts live from `/joint_states` (QoS risk from spec — if readouts stay empty, rosbridge failed best-effort matching; fix by relaying or explicit qos and re-verify).
- [ ] **Step 2:** Camera pane streams. STOP tap publishes `x` (verify via `ros2 topic echo /arm/cal` on armdell). Cal toggle + row select sends the channel digit.
- [ ] **Step 3:** Kill `arm-rosbridge`; buttons disable + banner; restart; auto-reconnect. Commit any fixes.

### Task 4: Kiosk on armdell

**Files (on armdell, not in repo):** `/etc/systemd/system/kiosk.service`
**Docs (in repo):** append kiosk unit + install steps to `docs/install/5-raspberry-pi.md` follow-on section or new `docs/install/6-touchscreen.md`.

- [ ] **Step 1:** `sudo apt-get install -y cage curl && sudo snap install chromium`.
- [ ] **Step 2:** Install unit: user jsamuel on tty1 (`PAMName=login`, `TTYPath=/dev/tty1`, `Conflicts=getty@tty1.service`), `ExecStartPre` waits for :8088, `ExecStart=/usr/bin/cage -- /snap/bin/chromium --ozone-platform=wayland --kiosk --noerrdialogs --disable-pinch --overscroll-history-navigation=0 http://localhost:8088`, `Restart=always`.
- [ ] **Step 3:** `systemctl daemon-reload && systemctl enable --now kiosk.service`; verify `systemctl status` active and user confirms UI on the Magedok; touch works. Fallback if cage+snap-Chromium fights (per spec): minimal X + `chromium --kiosk` under xinit.
- [ ] **Step 4:** Write `docs/install/6-touchscreen.md` (services, kiosk unit, URL), add to mkdocs nav, commit + push.

## Self-Review

- Spec coverage: page/layout (T1), services (T2), data flow + error handling + testing steps 1–4 (T1–T3), kiosk + test step 5 (T4). Dim-until-armed consciously dropped — recorded in Global Constraints.
- No placeholders; cal alphabet, ports, and URLs match the spec verbatim.
- Types: single `JointState` shape produced in T1 is what firmware `joint_index_from_name` consumes; no cross-task drift.
