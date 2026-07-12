# Webcam-assisted joint calibration

Derives the per-joint servo calibration values (`min_us`, `max_us`,
`center_offset`, `direction`) that go into `firmware/arm_controller/config.h`,
by sweeping one joint at a time while a webcam records what the arm
actually does.

## Why two scripts?

On macOS, ROS2/rclpy only exists inside the Docker container — and the
container cannot access the Mac's webcam. So the tooling is split:

| Script | Runs where | Does what |
|---|---|---|
| `calibrate_sweep.py` | inside the ROS2 container | publishes stepped `/arm/joint_commands`, printing a timestamp per step |
| `capture_frames.py` | on the Mac host (pure OpenCV, no ROS) | saves timestamped webcam frames into `captures/` |

Both print/embed the same wall-clock timestamp format, so frames can be
matched to commanded positions afterwards. (Container and host clocks agree
on Docker Desktop; both derive from the Mac's clock.)

## One-time setup (host side)

```bash
cd host/calibration
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Calibration workflow (per joint)

Safety first: for the first pass, power one servo at a time (USB-bench rules
in `hardware/wiring.md`), use a narrow range, and keep a hand near the power
switch. Start with conservative firmware defaults (e.g. 1000–2000 µs) so the
sweep cannot command past a mechanical stop.

1. **Start the stack** and confirm the ESP32 is registered:

   ```bash
   cd host
   docker compose up -d
   docker compose exec foxglove-bridge bash -c \
     "source /opt/ros/jazzy/setup.bash && ros2 topic echo /joint_states --once"
   ```

2. **Point the webcam** at the joint. Tape a paper protractor or angle
   reference behind the joint if you want degree-accurate readings.

3. **Start capturing** (Mac host terminal — start this BEFORE the sweep):

   ```bash
   cd host/calibration
   source .venv/bin/activate
   python3 capture_frames.py --interval-s 0.5 --prefix joint1
   ```

4. **Run the sweep** (second terminal). The compose file mounts this
   directory into the container at `/calibration`:

   ```bash
   cd host
   docker compose exec foxglove-bridge bash -c \
     "source /opt/ros/jazzy/setup.bash && \
      python3 /calibration/calibrate_sweep.py \
        --joint 1 --from-rad -1.2 --to-rad 1.2 --step 0.1 --dwell-s 2.0"
   ```

   Each step prints a timestamped line like:

   ```
   [2026-07-12T14:03:27.512] joint1 -> +0.300 rad (step 16/25)
   ```

5. **Stop the capture** (Ctrl-C) once the sweep prints `sweep complete`.

6. **Compare commanded vs observed.** For each commanded position, find the
   frames whose filename timestamp falls inside that step's dwell window and
   read the actual joint angle off the frames. Record:

   - the commanded radians at which the joint reaches each mechanical limit
     → work back to pulse widths for **`min_us` / `max_us`** (the firmware
     maps the configured radian range linearly onto `min_us..max_us`, so
     tighten those until commanded range == safe physical range);
   - the offset between commanded `0.0` and the true mechanical center
     → **`center_offset`** (µs);
   - whether positive radians move the joint in the kinematically-positive
     direction; if not → **`direction = -1`**.

7. **Record the values** in `firmware/arm_controller/config.h` for that
   joint, reflash, and re-run a short sweep to verify: commanded `0.0` is
   centered, both endpoints stop short of the mechanical stops, and the
   motion direction is correct.

8. Repeat for joints 2–6 (use `--prefix jointN` on the capture so frame
   sets don't mix).

## Useful options

- `calibrate_sweep.py --return-home` — send the joint back to 0 rad after
  the sweep.
- `calibrate_sweep.py --settle-s 4` — wait longer before stepping (big/slow
  joints).
- `capture_frames.py --device 1` — use an external USB webcam instead of the
  built-in camera.
- `capture_frames.py --duration-s 90` — auto-stop instead of Ctrl-C.

## Later

This capture path (webcam frames + commanded positions) is the seed for
phase-2 camera/perception work — the same tooling can feed frames into an
apriltag/aruco-based auto-calibration.
