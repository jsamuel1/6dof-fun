# Parts List (BOM)

Everything below is owned — the build requires no further purchases.
Prices are indicative street prices; the "search for" column gives generic
terms that find the part on any major electronics retailer.

| Item | Detail | Status | Indicative price | Search for |
|---|---|---|---|---|
| MCU | Elegoo ESP32 dev board — WiFi, USB-C, Arduino IDE compatible, 3.3V logic | owned | ~$10–12 | "Elegoo ESP32 development board USB-C" |
| Servo driver | PCA9685 16-channel I2C PWM board, address `0x40`, with V+ terminal block | owned | ~$6–10 | "PCA9685 16 channel PWM servo driver" |
| Servos | 6× MG996R metal-gear (4.8–7.2V; ~1A moving, 2.5A+ stall **each**) | owned | ~$25–35 for 6 | "MG996R servo 6 pack" |
| Servo power supply | 12V/10A power supply (repurposed car-style supply) | owned | ~$15–20 | "12V 10A power supply" |
| DC-DC converter | 12–40V input → 6V/10A output, 60W buck-boost module | owned | ~$12 | "DC buck converter 12V to 6V 10A 60W" |
| Rail capacitor | ≥1000µF across the 6V servo rail to absorb stall spikes — **already fitted: the PCA9685 board carries 1000µF onboard**, so no extra part is needed | owned (onboard) | $0 | — |
| Host computer | macOS + Docker now; spare Raspberry Pi later | owned | — | — |
| Webcam | Mac built-in camera or any USB webcam, for calibration observation | owned | ~$0–25 | "USB webcam 1080p" |
| 3D printer | Bambu Lab P2S — PLA for fit prototypes, PETG for final mounts | owned | — | — |
| Filament | PLA (prototypes) + PETG (final mounts) | owned | ~$20–25/kg | "PETG filament 1kg" |
| Wiring & misc | Short, thick wire for converter → PCA9685 V+ run; jumper wires for I2C; USB-C cable | owned | ~$5–10 | "silicone wire 16 AWG", "dupont jumper wires" |

!!! warning "Power budget"
    Six MG996R servos can transiently draw well over 10A if several stall at
    once. The 6V/10A converter plus the PCA9685's onboard 1000µF capacitor is
    sized for normal simultaneous motion, not six simultaneous stalls — the
    firmware's trajectory limits and software joint limits are part of the
    power design. Never bypass the converter: **12V directly on the servo rail
    destroys MG996Rs**. See [Install → Hardware](install/1-hardware.md).
