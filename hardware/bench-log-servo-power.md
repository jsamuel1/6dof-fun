# Bench Log — "servo doesn't move" investigation

Status: **RESOLVED 2026-07-14** — dead protection FET bypassed via unprotected V+ breakout; first motion achieved (raw wiggle; arm promptly fell over — see lessons) · Started 2026-07-14 · Symptom: full digital chain healthy,
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

## Worksheet results (2026-07-14 evening)

| Step | Result | Meaning |
|---|---|---|
| A | rows = Black/Red/Yellow = GND/V+/PWM | standard order; probing was correct |
| B | solid beep | GND path healthy |
| C | **fading beep** | no copper path terminal→rail *through the meter* (see root cause — a protection FET doesn't conduct at meter test voltage) |
| D | **~0.7 V** on rail with 6 V at block | rail effectively dead under power |
| H | 0 V + solid beep | logic/servo grounds solidly common |

## Root cause

Underside silk revealed this clone is **"reverse polarity protected"
at the terminal block** — a series protection device (P-FET) sits between
the terminal block V+ and the servo rail. With 6 V correctly applied it
should conduct; the rail instead shows ~0.7 V leakage → **the protection
device has failed open**. This explains every observation, including the
fading continuity beep (capacitor charging through the dead FET's path)
and why every digital test stayed green (logic VCC is a separate net).

The silk also notes the **"side breakout pins are not"** protected — the
V+ header pins/holes connect *directly* to the servo rail, bypassing the
dead device.

## Fix options

1. **Validate first (no solder):** temporarily feed 6 V to the populated
   header's V+ pin (where the removed blue jumper sat) via a female jumper
   from the converter yellow — single unloaded servo sweep only (a jumper
   wire is not rated for multi-servo current). Servo moves → diagnosis
   proven.
2. **Permanent, this board:** solder the converter's yellow 6 V wire into
   the empty V+ through-hole on the unpopulated header end (direct rail
   feed, mechanically strong). Black stays in the GND terminal. Trade-off:
   no reverse protection remains — acceptable given the color-documented
   wiring, but note it in wiring.md.
3. **Alternative:** locate and bridge the failed FET's pads (needs a
   top-side photo near the terminal block to identify the part).
4. **Replace the board** (~$6) if keeping protection is preferred.

## Resolution (2026-07-14, late)

Rail fed via the unprotected V+ breakout, bypassing the dead protection
FET → raw-pulse wiggle produced **first physical motion**. The unsecured
arm promptly fell over; channels disabled afterwards (board reboot forces
all channels off).

## Lessons / follow-ups

- The diag `w` wiggle drives ALL channels simultaneously at uncontrolled
  speed — fine for one bench servo, violent for an assembled arm.
  Follow-up: add per-channel wiggle (`0`–`5`) to the diag console; use slow
  ROS2 trajectories for anything assembled. **Secure the base before any
  multi-joint motion.**
- If the bypass is still the temporary jumper wire: single-servo testing
  ONLY until the converter's yellow wire is soldered into the V+
  through-hole — a jumper cannot carry multi-servo current (fire risk).
- ESP32 reset-loops on serial attach (recurring quirk): classic clone
  devkit auto-reset bounce; standard fix is a 10 µF capacitor from EN to
  GND. Parked until it bites during normal operation.
