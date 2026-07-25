# Connector ground truths (from fit-testing — do not re-derive)

Hard constraints learned from physical fit-tests and delivered hardware.
Any enclosure/design work must respect these; they are facts about the
parts in hand, not preferences. Sources: fit-test photos in `images/`
(2026-07-18 and 2026-07-24), Amass data, bench measurements.

## 6V power inlet — Amass XT60E-F (in hand, with gasket + kit screws)

- **It is the E-F (female), not the E-M** the design first assumed.
  Female on the case is correct for a load; the converter lead gets the
  male half.
- Flange **34 × 16** with rubber gasket; mounting ears Ø3 at **25 mm**
  spacing; needs a **flat** panel face ≥ ~35 × 17 — keep streamline
  curves/round-overs away from the flange zone.
- The body passes **bodily through the panel and reaches ~9 mm behind
  it**, solder cups at the rear plus wire-bend room (16 AWG bends at
  ~8 mm radius). Panel thickness ~2 mm (pocket a thicker wall down).
- Body cutout ~**16.6 × 13** (generous is fine — the gasketed flange
  covers it).
- Fit-test problem this caused: the body's inward reach collided with
  the PCA9685's entry-end header pins; the board now sits 10 mm off the
  entry wall (`pca_pin_clear`).

## PCA9685 — replacement BLUE clone (the green one died; kept as spare)

- **Right-angle 6-pin headers at BOTH board ends**: pins point
  horizontally out past the board edge, ~6 mm proud at ~10 mm above
  board-bottom datum. Each end needs a void; Dupont housings on the
  divider-end pins add another ~14 mm horizontally.
- **Board chirality**: with the I2C end connector facing the ESP32, the
  16-channel servo row lands on the BACK edge. This fixes which side
  the servo-lead exits are on — it cannot be flipped away.
- **Mid-board green V+/GND screw terminal WORKS** (unlike the old
  board): the 6 V feed lands here — zero soldering in the whole power
  path. Wires enter it from above; keep top access.
- Servo channels: vertical 3-pin columns (GND row nearest the board
  edge, V+ middle, signal inboard), plugs push straight down; plug +
  lead-bend stack ~14 mm above board top. Six leads used (CH0–5).

## ESP32 — 30-pin devkit

- Hookup pins are **scattered on one row** (the back row): from the
  antenna end, D22/SCL = pin 2, D21/SDA = pin 5 (TX0/RX0 between —
  never bridge them with a wide housing), GND = pin 14, 3V3 = pin 15.
- A standard Dupont housing is **14 mm long** — the dominant clearance
  everywhere it appears. Pins-down mounting means housings hang below
  the board: board underside must sit ≥ 16.5 above the floor.
- Corner screw holes at **46.5 × 23.3** (ruler-verified) — point
  supports there beat rails (connector access underneath).
- USB-C: plug body ~10.5 × 10 × 6.5 needs a straight approach bay
  (~12 mm) plus finger room; port height follows board height.

## Inline XT60 service disconnect

- Mated pair ~**24 × 8.2 × 8**; lives lengthwise on the PCA9685's
  front band; needs enough slack + open space above to pull apart with
  the lid off. Purpose: board removal without touching the panel
  connector or terminal.

## Meta-lessons from the fit tests

- Connector **bodies reach further than their face dims** — model the
  through-panel/behind-panel volume, not just the cutout.
- Every plug/housing needs its **mating travel** (insertion sweep), not
  just its seated envelope.
- Wires occupy real volume: 16 AWG pairs and servo trios need routed
  channels with ≥ wire-diameter spacing, and bend radii at terminations.
- The arm's own hardware protrudes on the mounting face: proud screws
  sit 18 mm OUTBOARD of each outer mount hole (row: screw–18–hole–18–
  hole–seam, mirrored). Underside relief for heads (Ø18×3 recess) and
  an M3 nut/tip (Ø9 through-hole; elongated at the floating end only).
