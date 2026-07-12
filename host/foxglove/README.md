# Foxglove layout for the 6DOF arm

`arm-layout.json` is an importable Foxglove layout with four panels:

| Panel | Purpose |
|---|---|
| **Plot** (top-left) | Live plot of all six `/joint_states.position[i]` values (radians), 30 s rolling window, y-axis clamped to ±3.3 rad |
| **Raw Messages** (bottom-left) | Raw view of `/arm/status` (JSON string: uptime, RSSI, agent link, e-stop) |
| **Publish — Send joint command** (top-right) | Editable `sensor_msgs/msg/JointState` template published to `/arm/joint_commands` |
| **Publish — Home** (bottom-right) | One-click "all joints to 0 rad" button |

## Connecting

1. Start the stack: `cd host && docker compose up`.
2. Open the Foxglove desktop app or <https://app.foxglove.dev>.
3. **Open connection** → **Foxglove WebSocket** → `ws://localhost:8765`
   (from another machine, use the host's LAN IP instead of `localhost`).

## Importing the layout

In Foxglove, open the **Layouts** menu (left sidebar) → **Import from file…**
→ select `host/foxglove/arm-layout.json`. Alternatively use the layout
dropdown in the top bar → **Import from file…** (the exact menu location
moves between Foxglove releases, but layout import-from-file is always
available).

> **Heads-up:** Foxglove does not guarantee the layout JSON format is stable
> between releases. This layout was written against the format used by
> Foxglove app exports as of mid-2026. If import fails or a panel comes in
> blank, recreate that panel by hand (below) and re-export your own layout to
> replace this file.

## Setting up the Publish panel manually (if needed)

The Publish panel is the one most likely to need per-user setup, because it
must infer the message schema from a live connection:

1. Add a **Publish** panel.
2. Set **Topic** to `/arm/joint_commands`. With the bridge connected and the
   ESP32 registered, Foxglove auto-detects the schema
   `sensor_msgs/msg/JointState`. If the topic doesn't exist yet (arm
   offline), type the schema name manually.
3. Switch the panel to the JSON editor view and paste:

   ```json
   {
     "header": { "stamp": { "sec": 0, "nanosec": 0 }, "frame_id": "" },
     "name": ["joint1", "joint2", "joint3", "joint4", "joint5", "joint6"],
     "position": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
     "velocity": [],
     "effort": []
   }
   ```

4. Edit `position` values (radians) and hit the publish button.

Notes:

- You can command a subset of joints — e.g. `"name": ["joint3"],
  "position": [0.8]`. The firmware matches joints by name.
- `velocity` may optionally carry a per-joint max velocity (rad/s) matching
  `name` order; leave it `[]` to use firmware defaults.
- Client publishing is enabled by default in `foxglove_bridge`; if the
  publish button is greyed out, check that you are connected via the bridge
  (not a data file) and that the bridge log shows no capability errors.

## Publishing a command without Foxglove

From the running stack:

```bash
docker compose exec foxglove-bridge bash -c \
  'source /opt/ros/jazzy/setup.bash && ros2 topic pub --once /arm/joint_commands sensor_msgs/msg/JointState "{name: [joint1], position: [0.5]}"'
```
