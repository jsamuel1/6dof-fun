# Design Decisions

ADR-style records of the seven decisions that shaped the system. Each states
the context, the decision, and its consequences (good and bad).

## ADR-1: ESP32 over Arduino Uno R3

**Context.** The controller must drive six joints smoothly over WiFi and run a
micro-ROS client. An Uno R3 was available, but it has no WiFi, an 8-bit
16MHz CPU, and 2KB of RAM.

**Decision.** Use an Elegoo ESP32: WiFi on-chip, 240MHz dual-core, and enough
RAM for per-joint trajectory interpolation — while staying Arduino-IDE
compatible so the toolchain stays simple.

**Consequences.** Wireless ROS2 control and headroom for the 50Hz
interpolation loop. 3.3V logic must be respected on the I2C bus (the PCA9685
is fine with it). The exact Elegoo module pinout varies slightly between
revisions and must be confirmed at flash time.

## ADR-2: micro-ROS over a custom protocol + bridge

**Context.** The arm could speak a simple custom UDP/serial protocol with a
host-side bridge translating to ROS2, or run micro-ROS and be a native node.
Staying aligned with the ROS2 ecosystem is a stated user priority.

**Decision.** Run micro-ROS on the ESP32. The arm is ROS2-native from day one.

**Consequences.** Foxglove, MoveIt, Strands-Robots, and every ROS2 tool work
against the arm without translation code. Costs: higher firmware complexity,
and the micro-ROS agent must be running for the arm to be reachable — which is
why the firmware has an explicit link-loss watchdog (ADR-4).

## ADR-3: Foxglove over an ESP32-served web UI

**Context.** The arm needs a browser control UI with sliders and live plots.
The ESP32 could serve its own web page, or a host-side bridge could expose
ROS2 topics to an existing UI.

**Decision.** Use Foxglove via `foxglove-bridge` on the host, with a shipped
layout (`host/foxglove/arm-layout.json`).

**Consequences.** Zero UI code on the MCU, native ROS2 topic access, and
plots/teleop/camera panels for free. A custom web UI can still be added
host-side later (rosbridge + static page) without any firmware change. Cost:
control requires the host stack to be up, and Foxglove is a third-party tool.

## ADR-4: Hold position on link loss, not go-limp

**Context.** When the agent link drops, the firmware must choose: keep
holding the servos at their last position, or stop sending pulses (go limp).

**Decision.** On agent-link loss longer than 2 seconds, hold the last
position, then auto-reconnect and re-register.

**Consequences.** A limp arm falls under gravity — holding is the safe
failure mode for a tabletop arm. Cost: servos keep drawing holding current
during an outage, and a truly stuck pose needs a manual power cut (which is
why the power-up checklist requires a known, instant way to cut servo power).

## ADR-5: Commanded-position joint states

**Context.** `/joint_states` conventionally reports measured positions, but
the MG996R has no position feedback of any kind.

**Decision.** Publish the commanded (interpolated) angle per joint at 20Hz.

**Consequences.** Standard practice for this hardware class, and it keeps the
interface MoveIt-compatible. Cost: the reported state diverges from reality
if a joint stalls or is overpowered — the webcam calibration workflow exists
partly to bound that error, and true feedback stays a hardware upgrade path.

## ADR-6: ProperDocs + MaterialX over MkDocs + mkdocs-material

**Context.** The docs site needs a static generator with Markdown, Mermaid,
and GitHub Pages deployment. Original MkDocs development stalled.

**Decision.** Use ProperDocs with the MaterialX theme — the
community-maintained successors, drop-in compatible with the MkDocs +
mkdocs-material ecosystem (`properdocs.yml` config, `materialx` theme,
`properdocs gh-deploy` to Pages).

**Consequences.** Actively maintained tooling with the familiar
Material-style config, features, and plugin ecosystem. Cost: slightly smaller
community than MkDocs had at its peak; docs/answers written for MkDocs
usually apply but occasionally differ.

## ADR-7: 12V/10A supply + 6V converter over a dedicated 6V supply

**Context.** Six MG996Rs need a 6V rail able to source large transient
currents. A 12V/10A car-style supply was already owned; a dedicated 6V/10A+
supply would be a new purchase.

**Decision.** Reuse the 12V/10A supply and feed a 12–40V-input → 6V/10A 60W
buck-boost converter (~$12, the only purchased item). The converter's input
range was verified to cover the 12V supply.

**Consequences.** Cheapest path using owned hardware, and the wide-input
converter survives a future supply swap. Costs: one more component in the
power chain, the converter's setpoint must be verified at 6.0V before every
first connection, and the hard rule stands — 12V must never reach the servo
rail or PCA9685 V+ directly.
