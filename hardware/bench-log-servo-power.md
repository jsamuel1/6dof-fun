# Bench Log — "servo doesn't move" investigation

Status: **open** · Started 2026-07-14 · Symptom: full digital chain healthy,
zero physical motion on any channel.

## Observations so far

| # | Test | Result | Interpretation |
|---|---|---|---|
| 1 | ROS2 → ESP32 command round-trip (`/joint_states` tracks commands) | ✅ works | WiFi/micro-ROS/firmware chain good |
| 2 | Firmware boot: `PCA9685 initialized` at 0x40 | ✅ works | I2C wiring correct |
| 3 | I2C scan + register readback (diag `i`) | ✅ 0x40 only; MODE1=0x20, MODE2=0x04, PRESCALE=0x83 | Firmware's 50 Hz config verifiably lands on the chip |
| 4 | Raw-pulse wiggle, all 16 channels, run twice (diag `w`) | ❌ no motion | Fault is downstream of the PCA9685's digital side |
| 5 | Terminal block screws, 12 V on | ✅ +6.0 V, correct polarity | Converter + wire clamps deliver power *to the block* |
| 6 | 1000 µF cap temperature/shape | ✅ cool, not bulging | No reversed-electrolytic damage |
| 7 | Channel pins: middle ↔ edge, 12 V on | ❌ 0 V, then −103 mV | Servo rail appears DEAD at the pins (or probes not on V+/GND) |
| 8 | Continuity: V+ screw ↔ middle pin | ⚠️ beep fades out (~1 s) | Capacitor-charging signature = capacitive path only. A solid copper path beeps continuously. Implies probes were effectively across V+/GND, **or** the V+ trace is broken |
| 9 | ESP32 reset-loop + WiFi-drop episodes | ⚠️ intermittent | Power-integrity watch item; possibly serial-attach artifacts; monitor |
| 10 | Servo orientation / health | ❓ untested | Not yet isolated from the rail question |

**Contradiction to resolve:** #5 says the block has 6 V; #8's fade-out says
block-to-rail isn't solid copper; #7 says the rail is dead. If the fade-out is
real (not probe slip), a **broken V+ path between terminal block and channel
rail** explains every observation, including why all digital tests stay green.

## Measurements needed (in order)

| # | Measurement | Setup | Expected if healthy | If not |
|---|---|---|---|---|
| A | Photo: channel banks + terminal block, straight down, pin-base colors visible | camera | Row order confirmed (usually black=GND edge, red=V+ middle, yellow=signal inner) | Clone has nonstandard rows → re-aim probes |
| B | Continuity: GND screw ↔ edge pin | 12 V OFF, meter beep | Solid continuous beep | GND path broken (unlikely) |
| C | Continuity: V+ screw ↔ middle pin | 12 V OFF, meter beep | Solid continuous beep | **Fading beep = V+ trace break — fault found** |
| D | DC volts: GND screw ↔ middle pin | 12 V ON | +6.0 V | Rail dead: inspect/reflow terminal-block solder tabs on board underside |
| E | Photo: probes in position during C/D | camera | Confirms probe placement | — |
| F | Servo plug: brown at board edge; then swap in a second servo | after rail confirmed live | Motion on diag `w` | Servo-side fault |
| G | If C fades: inspect terminal-block underside solder joints, reflow | iron | Solid beep after reflow | Board replacement (~$6) |

## Tools

- Firmware serial diag console (115200): `h` help · `i` I2C scan · `s` state ·
  `w` wiggle all channels · `x` disable all
- All 16 middle pins share one V+ rail — any channel is representative.
