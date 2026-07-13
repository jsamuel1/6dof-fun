# Install 4/4 — First Motion

This is the scripted bring-up checklist: verify the ROS2 plumbing, sweep one
servo on USB power, calibrate each joint with the webcam workflow, then power
the full arm. **Do the steps in order** — each stage validates the next one's
assumptions.

## 1. ROS2 smoke tests

There is no ROS2 on the Mac itself, so run the `ros2` CLI inside the
`foxglove-bridge` container. Its entrypoint does not auto-source the ROS
environment for `docker compose exec`, so every command sources
`setup.bash` explicitly (the `micro-ros-agent` container's entrypoint is the
agent binary — `ros2` is not on its exec PATH). With the stack up and the
ESP32 connected:

```bash
cd host
docker compose exec foxglove-bridge bash -c \
  "source /opt/ros/jazzy/setup.bash && ros2 topic list"
```

Expect to see:

```
/arm/joint_commands
/arm/status
/joint_states
```

Then confirm data is flowing:

```bash
docker compose exec foxglove-bridge bash -c \
  "source /opt/ros/jazzy/setup.bash && ros2 topic echo /joint_states --once"
docker compose exec foxglove-bridge bash -c \
  "source /opt/ros/jazzy/setup.bash && ros2 topic hz /joint_states"   # ~20 Hz
docker compose exec foxglove-bridge bash -c \
  "source /opt/ros/jazzy/setup.bash && ros2 topic echo /arm/status --once"
```

`/arm/status` is a JSON string with uptime, WiFi RSSI, agent-link state, and
the e-stop flag.

## 2. Single-servo sweep (USB power only)

USB power can safely drive **one** unloaded servo. Connect a single MG996R to
PCA9685 **channel 0**, horn detached, servo not attached to the arm.

```bash
docker compose exec foxglove-bridge bash -c \
  'source /opt/ros/jazzy/setup.bash && ros2 topic pub --once /arm/joint_commands sensor_msgs/msg/JointState "{name: [joint1], position: [0.3]}"'
```

The servo should move smoothly (no snap) to the target. Send a few targets
either from the CLI or the Foxglove joint command panel (name `joint1`) and watch
`/joint_states` track the commanded trajectory. If the ESP32 brownouts or the
servo chatters, stop — that's a wiring/power problem, not a software one.

## 3. Joint-by-joint calibration (webcam-assisted)

The MG996R gives no feedback, so calibration is visual: the script in
`host/calibration/` sweeps one joint at a time while capturing webcam frames
(ROS2 + OpenCV), letting you compare actual motion against commanded angles.

For **each** joint, one at a time, servo powered from the converter rail:

1. Run the calibration sweep for the joint (see `host/calibration/` for the
   script and its options — joint name, sweep range, camera index).
2. From the captured frames, determine the servo's true travel and center:
   the pulse widths where it reaches its mechanical extremes, the offset that
   makes the commanded zero the real zero, and whether its rotation sense is
   inverted.
3. Record the values into `firmware/arm_controller/config.h` as that joint's
   `min_us`, `max_us`, `center_offset`, and `direction`, plus its software
   joint limits.
4. Re-flash and re-run the sweep to confirm commanded and observed motion
   match.

The same script is the seed for later camera/perception work, so time spent
here is not throwaway.

## 4. Full-arm power-up checklist

Only after all six joints are calibrated:

- [ ] Converter output re-verified at **6.0V** with a multimeter, under no load.
- [ ] Converter → PCA9685 V+ wiring short and thick; grounds common with ESP32.
- [ ] `config.h` contains real calibration values and sensible joint limits
      for all six joints; firmware re-flashed.
- [ ] Servo horns attached with each joint at its calibrated zero.
- [ ] The arm's workspace is clear; you can cut servo power instantly
      (switch or unplugging the converter output — know which before you start).
- [ ] Power up. Nothing should move: servos idle until the first command.
- [ ] `/arm/status` shows agent link up; `/joint_states` at 20Hz.
- [ ] Command **one joint, a few degrees, slowly** from the Foxglove joint
      command (Publish) panel. Verify motion direction and magnitude.
- [ ] Try to command a joint past its software limit and confirm the firmware
      clamps it.
- [ ] Watchdog test: stop the agent (`docker compose stop micro-ros-agent`)
      mid-pose and confirm the arm **holds position** (does not go limp); start
      it again and confirm the node reconnects and re-registers.
- [ ] Move through slow poses across all six joints via Foxglove.

## Troubleshooting: firmware reports `agent ping failed rc=1`

`rc=1` is a *local* send error — the probe never left the board — as opposed
to `rc=6` (probe sent, no answer). The most common cause: **the ESP32 and the
Docker host are not on the same network segment**. The ESP32 ARPs for the
agent IP and gets no reply (client isolation between WiFi bands/SSIDs, a
guest network, or a host on a different subnet), so the transport errors out
before anything reaches the wire. Fix: put both devices on the same
SSID/segment, confirm with `ping <esp32-ip>` from the host, and re-check the
host's LAN IP (`ipconfig getifaddr en0`) — update `AGENT_IP` in `config.h`
if it changed (DHCP renumbers hosts that switch networks; consider a DHCP
reservation for the Docker host).

Done — the arm is live. Take photos for the [gallery](../gallery.md), and see
[3D Printing](../3d-printing.md) for mounting the boards on the arm.
