# Wiring Guide — 6DOF Arm Electronics

Complete hookup for the Elegoo ESP32 dev board, PCA9685 servo driver,
six MG996R servos, and the 12 V → 6 V servo power chain.

> **Read the [safety rules](#safety-rules) before plugging anything in.
> The single fastest way to destroy all six servos is putting 12 V on
> the PCA9685 V+ terminal.**

## System diagram

```
                 WiFi (micro-ROS / XRCE-DDS over UDP :8888)
  Mac / Pi host  <~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>  ESP32
                                                              |
  USB-C 5V (programming + logic power) ----------------------+

           +------------------------------------------+
           |            ESP32 dev board               |
           |            (3.3 V logic)                 |
           |   3V3     GPIO21    GPIO22     GND       |
           +----+---------+---------+--------+--------+
                |         |         |        |
                |  I2C @ 3.3 V, address 0x40 |
                |         |         |        |
               VCC       SDA       SCL      GND
           +----+---------+---------+--------+--------+
           |              PCA9685                     |
           |    16-ch PWM driver, 1000uF cap onboard  |
           |                                          |
           |  V+  GND          CH0 CH1 CH2 CH3 CH4 CH5|
           +---+---+------------+---+---+---+---+---+-+
               |   |            |   |   |   |   |   |
               |   |           J1  J2  J3  J4  J5  J6   (MG996R x6)
               |   |
        +------+---+-------+         +------------------+
        |  6 V / 10 A OUT  |         |                  |
        |  buck converter  |<--------+  12 V / 10 A PSU |
        |  (12-40 V input) |  12 V   |  (mains supply)  |
        +------------------+         +------------------+

        ALL GROUNDS COMMON: PSU(-) -> converter(-) -> PCA9685 GND
                                                   -> ESP32 GND
```

## ESP32 ↔ PCA9685 (I2C logic side)

Four female-female jumper wires to the PCA9685's 6-pin I2C header
(either short end of the board — both ends carry the same signals).

| ESP32 pin | PCA9685 pin | Purpose | Notes |
|---|---|---|---|
| `3V3` | `VCC` | Logic supply | **3.3 V only.** VCC powers the PCA9685 chip, not the servos. Do not use the ESP32 5 V/VIN pin — keep I2C levels at 3.3 V. |
| `GPIO21` | `SDA` | I2C data | Default Arduino `Wire` SDA on ESP32. |
| `GPIO22` | `SCL` | I2C clock | Default Arduino `Wire` SCL on ESP32. |
| `GND` | `GND` | Logic/signal ground | Also ties the ESP32 into the common ground (see below). |
| — | `OE` | Output enable | Leave unconnected. It is pulled low (outputs enabled) on standard boards. Optionally wire to a spare GPIO for a hardware kill switch (drive HIGH to disable all PWM). |

- I2C address: `0x40` (all address jumpers open — the default).
- No external pull-up resistors needed: standard PCA9685 boards have
  10 kΩ pull-ups to VCC on SDA/SCL, which is why VCC must be 3.3 V.

## Servo channel assignments

Servo plugs go onto the PCA9685's 3-pin output columns. Pin order on
the board, from the outer edge inward: **GND (bottom), V+ (middle),
PWM (top)**. MG996R lead colors: **brown = GND, red = V+,
orange = signal**. Brown faces the board edge.

| PCA9685 channel | ROS2 joint name | Position on arm |
|---|---|---|
| 0 | `joint1` | Base rotation (yaw) |
| 1 | `joint2` | Shoulder pitch |
| 2 | `joint3` | Elbow pitch |
| 3 | `joint4` | Wrist pitch |
| 4 | `joint5` | Wrist roll |
| 5 | `joint6` | Gripper |
| 6–15 | — | Unused (spares for future grippers/sensors) |

The channel → joint mapping is fixed in firmware (`config.h`); if you
plug a servo into the wrong channel, move the plug rather than editing
firmware, so the table above stays true.

## Servo power path

```
12 V/10 A supply  →  buck converter (12–40 V in, 6 V/10 A out)  →  PCA9685 V+ terminal
```

| Segment | Connection | Wire | Notes |
|---|---|---|---|
| PSU → converter | 12 V out (+/−) → converter IN (**red** = +, paired **black** = −) | 16 AWG | Converter input range 12–40 V covers the 12 V supply. |
| Converter → PCA9685 | 6 V OUT (**yellow** = +) → `V+` screw terminal; OUT (paired **black** = −) → `GND` screw terminal | 14–16 AWG, **as short as practical** | Six MG996Rs draw ~1 A each moving and 2.5 A+ each at stall; keep this run short and thick to limit voltage sag. |
| Stall-spike capacitor | — | — | The PCA9685 already carries a 1000 µF electrolytic across V+/GND — that satisfies the ≥1000 µF rail-cap requirement. No extra cap needed unless you lengthen the power run. |
| ESP32 logic power | USB-C from host/charger | — | The ESP32 is **not** powered from the servo rail. |

Wire colors are straight from the unit's label (input: red +, black −;
output: yellow +, black −). The two black wires are per-bundle negatives —
use each with its own side.

Set the converter's output to **6.0 V** with a multimeter *before*
connecting the PCA9685 (MG996R range is 4.8–7.2 V; 6 V is the sweet
spot of torque vs. heat).

## Common ground — required, not optional

The I2C signals are referenced to ground. Every ground in the system
must be connected together:

- 12 V PSU (−) → converter IN (−) *(inherent in the power wiring)*
- Converter OUT (−) → PCA9685 `GND` screw terminal *(inherent)*
- ESP32 `GND` → PCA9685 I2C header `GND` **(the jumper wire in the I2C
  table — do not skip it)**

Without the ESP32↔PCA9685 ground jumper, I2C will be flaky or dead and
the servos may twitch unpredictably.

## Safety rules

1. **NEVER connect the 12 V supply directly to the PCA9685 V+ terminal
   or to any servo.** 12 V destroys MG996Rs (rated 4.8–7.2 V). The 12 V
   supply connects to the buck converter input, nothing else.
2. **USB power = single-servo bench testing only.** A USB port cannot
   source the current of even one loaded MG996R, let alone six. Full-arm
   motion requires the 6 V/10 A converter rail. (For single-servo USB
   tests, the servo still plugs into a PCA9685 channel with V+ fed at
   5 V from a bench source — never backfeed servo current through the
   ESP32's 5 V pin.)
3. **Verify converter output is 6.0 V under no load before first
   connection**, and re-check polarity at the V+ terminal with a meter.
   Reverse polarity kills the PCA9685 instantly.
4. **Keep converter → PCA9685 wiring short and thick** (14–16 AWG).
   Six stalled servos can transiently pull 15 A+; thin or long wires
   brown-out the rail and reset everything.
5. **Power-up order:** ESP32 via USB first (servos idle — firmware sends
   no pulses until the first valid command), then switch on the 12 V
   supply. Power-down in reverse.
6. **Mind pinch points.** On agent-link loss the arm holds position
   rather than going limp — it will not drop, but it also will not yield.
   Keep fingers clear and kill the 12 V supply to make the arm safe to
   handle.

## Bench bring-up checklist (wiring portion)

1. All grounds common (beep test PSU−, converter−, PCA9685 GND, ESP32 GND).
2. Converter output trimmed to 6.0 V, verified with a meter, no load.
3. I2C jumpers: 3V3→VCC, 21→SDA, 22→SCL, GND→GND.
4. ESP32 on USB: firmware boots, I2C scan finds `0x40`.
5. One servo on channel 0, V+ powered: single-servo sweep test.
6. Remaining five servos on channels 1–5 per the table above.
7. Full-arm motion only on converter power, never on USB.
