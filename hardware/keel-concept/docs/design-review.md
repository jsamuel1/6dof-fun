# Keel v3 — deep design review

Honest review of the current design (drawers under the arm, centreline
WAGO junction, through-body clamps). Verdicts: ✓ sound, ⚠ needs a tweak,
✗ needs a design change before printing.

## v3.1 — resolutions applied 2026-07-26

1. **H 36 → 38** ✓ — 2.6 mm air over the upright ESP32; sleds bear
   directly on the floor.
2. **Raceways deleted, not deepened** — a 4 mm channel can't live in a
   2.5 mm floor. Wires run the tunnel/tray corners through the floor-level
   wall pass-throughs; the click-off base opens every run from below.
3. **Floating ledge rails fixed** — they hovered 2.6 mm above the floor
   with nothing under them (unprintable) and lifted the sled out of the
   height budget. Now solid floor-level side guides. **Printed detents**
   (guide bump + sled-edge scallop) replace the magnet option — zero BOM.
4. **Servo service ✓ — coupler comb**: a flat shelf drops into grooves
   across the junction tray *above* the WAGO lanes; the 6 extension
   couplers lie in its channels. Unplug at the comb → PCA drawer slides
   out on short pigtails through the widened 19 × 14 service window; lift
   the comb out (leads attached) → full WAGO access. +6 extension leads.
5. **Deck stiffening**: full-width 8 mm cross-ribs would hit the upright
   ESP32 — instead four Ø10 M4 boss columns under the deck at the adapter
   screw points. (They were bore-only before: the head recess had no
   material around it.)
6. **ESP32 drawer face** gets a USB-C extension window (flange **MEASURE ME**).
7. `keel_base.scad` **didn't parse** — `snap_sockets()` had lost its
   module header. Fixed.

Still open (measurements): bracket-foot holes, buck holes, USB-C flanges,
coupler body, bench thickness.

## 1. Constraints & height budget

- ⚠ **H = 36 is 0.6 mm from failure.** Floor 2.5 + sled 1.6 + ESP32 width
  28.9 + deck 2.4 = 35.4. No allowance for the cradle base, first-layer
  squish, or PCB edge tolerance. **Go to H = 38.**
- ✓ Drawer width: 1.6 PCB + 14 mm Dupont (pins inboard) + cradle ≈ 18 of
  the 34 mm tunnel — comfortable, with a wire channel left over.
- ⚠ Floor raceways are 1.5 mm deep; a 16 AWG pair stacks ~3.6 mm.
  **Deepen raceways to 4 mm** (floor locally 6.5) or route along tunnel
  corners instead.

## 2. Assembleability

- ✗ **Floor and shell have no joint.** They are separate `.scad` parts
  with nothing fastening them. Fix: print as ONE body (208 mm fits a
  256 mm bed diagonally), or add 6 screw bosses. Recommended: one body;
  keep `floor`/`shell` split only for printers that need it.
- ✓ (resolved) Arm mounting now goes through a **separately printed
  adapter plate**: bracket feet bolt to the adapter (M3), adapter screws
  to the body with 4 × M4 from below via deck bosses. Fit-tests and
  future arms swap a 40-minute adapter print, not the body. Boss
  positions still need the real bracket-foot **MEASUREMENT**.
- ⚠ Drawer retention: nothing stops a drawer creeping out under
  vibration. Add either a printed detent bump or **4× Ø6×2 magnets**
  (sled tail + tunnel rear).
- ✓ Clamps: T-head recess, through-slot, M6 heat-set in the jaw, printed
  octagonal knob — assembles with 2 heat-sets and 2 screws. (The 3D
  model's spine is drawn short; the scad length `throat+4+H` is correct.)

## 3. Servicing access

- ✓ Buck: lift chamber lid → slide sled out.
- ✓ WAGO rails: lift junction lid; levers up, entries up; both lanes
  reachable.
- ✓ ESP32: flash via the face USB-C without opening anything; pull the
  drawer for board swap.
- ✗ **PCA drawer can't actually slide out while 6 servo leads run to the
  grommet.** The header is under the fixed deck, so you can't unplug
  first. Fix (pick one):
  1. **Bulkhead comb** (recommended): 6 servo extension couplers parked
     in a printed comb at the tunnel rear, reachable through the junction
     tray with its lid off. Drawer carries only short pigtails.
     Adds: 6× servo extension leads.
  2. Give the PCA position a lidded tray instead of a drawer (reverts
     half the benefit).
- ⚠ Drawer service loops: VIN + I2C into the ESP32 drawer need ~100 mm
  of slack folded in the tunnel wire channel — works, but model the clip
  path before printing.

## 4. Cable space

- ✓ Junction gully between + and − lanes; feed pass-through from chamber;
  per-drawer pass-throughs.
- ✓ Grommet Ø9 bore fits 6 × 3-wire ribbon (~8.5 mm bundled).
- ⚠ Raceway depth (see §1). ⚠ USB-C panel extension to the ESP32 drawer
  face must flex with drawer travel — use a 200 mm extension, not 100.

## 5. Strength

- ✓ Torsion from arm slew: 4-screw pattern over a 48 × 60 spread into
  bosses is ample for MG996R-class torque.
- ⚠ Deck is a 94 mm span of 2.4 mm PETG under the arm feet. The solid
  spine between tunnels (z ±10) carries it, but add two cross-ribs under
  the deck at the foot rows (x ≈ 16, 64), 4 × 8 mm, spanning wall to
  wall. Print deck-side down is not possible (single body prints
  upright) — 25 % infill, 5 walls for the body.
- ✓ Clamp load path: spine in a full-depth slot, head on the deck — far
  better than the old screw ear.

## 6. Stability (the honest numbers)

Moments about the front foot line (x = 72): a ~0.8 kg arm fully extended
puts ~180 kg·mm of overturning moment there. The keel + 200 g ballast +
arm base return only ~75 kg·mm. **Free-standing, the arm WILL tip at
full forward reach.** Options, in order:

1. **Clamps on** (they exist for exactly this, and sit at the wide arm-end
   edge where the tipping moment acts) — rigid, solved.
2. ~1 kg of ballast (both lobes + a steel plate in the chamber floor) —
   heavy but cable-free.
3. Keep free-standing use to ≤ half reach / low speed.

The slimmer 124 mm width did not change forward tipping (that's set by
length), and side stability is still fine: side reach moment is smaller
and the 124 mm track with feet at ±50 holds it.

## 7. Extra parts (full sourced-parts list)

| Part | Qty | For |
|---|---|---|
| WAGO 221-415 | 4 | junction rails |
| Bridge jumper 1.5 mm², 30 mm | 2 | rail pairs |
| Adafruit HUSB238 STEMMA QT | 1 | USB-C PD sink |
| Pololu ORing ideal-diode pair 4–60 V 6 A | 1 | dual inlet |
| Panel DC barrel jack Ø11.2 | 1 | 12 V in |
| USB-C panel extension, 200 mm | 2 | PD in + ESP32 service |
| Servo extension leads | 6 | bulkhead comb (§3) |
| M2.5 × 6 self-tap | 8 | PCA + buck standoffs |
| M3 heat-set + M3 × 10 | 4 + 4 | arm feet → deck bosses |
| M6 heat-set + M6 × 70 | 2 + 2 | clamp screws |
| M4 × 12 + nut | 4 | clamp extension splice (optional) |
| Ø6 × 2 magnets | 4 | drawer detents |
| STEMMA QT cable | 1 | ESP32 → HUSB238 (I2C) |
| Steel shot ~200 g (or up to 1 kg, §6) | — | ballast |

## Action list before first print

1. H 36 → 38; raceways 4 mm.
2. Merge floor + shell into one printed body.
3. Move arm-foot screws to bossed positions (after measuring the real
   bracket feet).
4. Add the servo bulkhead comb + extension leads.
5. Drawer magnets/detents; deck cross-ribs.
6. Measure: bracket-foot holes, buck holes, USB-C extension flanges,
   bench thickness.

## v3.2 — usability fixes applied 2026-07-26

- **Clamp direction was reversed** in the model: the jaw now reaches back
  INBOARD under the benchtop the keel sits on; the spine drops through
  the slot past the bench edge. The clamp corners overhang the edge
  ~20 mm, so the front feet moved inboard (x 72 → 56) to stay on the
  bench.
- **Clamp stowage**: clamps fold flat on the deck, arms inboard, T-heads
  at the flank edges, clipped under printed stow posts + lips.
- **Transom is part of the base**: the power wall (jack + both USB-C
  extensions) rises from the click-off floor into a shell notch; the
  chamber lid caps the joint. Popping the base no longer tears the
  panel-mounted connectors off their wiring. (The HUSB238/ORing shelf
  now fuses to it — it floated unattached in the shell before.)
- **Base screws from outside**: the 4 side M3s are gone — countersunk
  M3s go UP through the floor into shell-wall boss pads. Fastenable
  with the keel on the bench; the TPU feet keep the heads clear.
- **Drawer mouths open at the bottom** — the red "sill trims" are
  deleted (they were left floating whenever the base dropped); drawers
  ride the base out.
- Viewer housekeeping: Card + Tap archived to `mounts-archive.js`.

## v3.3 — applied 2026-07-26

- **Drawer mouths actually open now**: the viewer shell's tunnel cutouts
  crossed the outline edge, which the triangulator can't hole — the
  front wall rendered solid. The mouths are open bays in the outline
  itself; the scad base lip is notched at the mouths so the drawer
  faces pass.
- **WAGO rails, pixelwave-style** (MakerWorld #70798 as concept
  reference; our own geometry): one clip fin at each end of EACH
  221-415 — any single clamp unsnaps from its rail without disturbing
  the other three.

## v3.4 — applied 2026-07-26

- **The clamp could never be installed**: one printed piece, but neither
  the T-head (28 wide) nor the jaw (34 wide) passes the 21 × 11 body
  slot. Now two prints: the spine + T-head drops in from above; the jaw
  bolts to its lower end with 2× M4 + nuts (same splice joint as the
  extension, which now inserts between spine and jaw). No screws into
  the body; the M6 thumbscrew stays hand-tight.
- **Viewer: lintel restored over each drawer mouth** — the open bays were
  cut full-height; the physical opening stops at the deck.

## v3.5 — applied 2026-07-26

- **Servo egress moved to the centreline**, at the arm-side edge of the
  junction tray lid: U-notch in the lid + relief in the shell rim, lined
  by a slit **TPU edge bushing** (Ø9 bore) so the harness never bears on
  a printed PETG edge. Unclip the bushing and the lid lifts off past the
  cables. Replaces the deck-band grommet at z +52 (bore + wall channel
  deleted).
