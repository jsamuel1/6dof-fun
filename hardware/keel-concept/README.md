# Handoff: Keel base — arm processor bracket (v3.7)

## Overview

The "Keel" is an integrated base plinth for a 6-DOF hobby-servo arm
(MG996R class, ESP32 + PCA9685 driven). It replaces the old
`electronics_spine` that rode on the arm itself: all boards, the whole
power chain, and ballast now live in a plinth **under** the arm, so
nothing is added to the motion envelope.

**208 × 124 × 38 mm** (+4 mm TPU feet). Two slide-out drawers under the
arm (ESP32 on its side, PCA9685 flat), an aft power chamber (buck +
USB-C PD sink + ORing diode pair), a centreline WAGO servo-power
junction tray, a lift-out **coupler comb** where the arm's servo harness
plugs in, ballast lobes, and two optional through-body desk clamps.

The task in the codebase: bring the parametric OpenSCAD source up to the
state shown in the viewer (currently at **v3.1** in `.scad`, **v3.7** in
the viewer), then produce print-ready STLs.

## About the design files

The files in this bundle are **design references**, not production
source:

- `Arm board mounts.html` + `mounts.js` + `parts-view.js` +
  `three-d-stage.js` — an **interactive three.js concept model**. It is a
  fast, throwaway representation used to reason about fit, service access
  and assembly order. It is built from boxes and cylinders; it is *not*
  a manifold solid, has no tolerances baked in, and must never be
  exported as geometry.
- `openscad/keel_base.scad`, `board_card.scad`, `buck_tap.scad` — the
  **real** parametric source path (`board_card` / `buck_tap` are archived
  alternative concepts, superseded).
- `docs/board-mount-concepts.md`, `docs/design-review.md` — the design
  rationale and the honest review, including open measurements.

The deliverable is **parametric OpenSCAD in the existing repo**
(`jsamuel1/6dof-fun`, branch `main`, subtree `hardware/`), following that
repo's conventions: `include <common_params.scad>`, its `vent_slot()`,
`standoff()` and pilot-diameter helpers, a `part = "…"` selector at the
top of each file, and the house rule **print flat as modelled, no
supports**. Where the viewer and the `.scad` disagree, the viewer is the
newer intent — but re-derive every dimension parametrically rather than
transcribing the viewer's literals.

## Fidelity

**Hi-fi in intent, lo-fi in geometry.** Every dimension in this document
is either measured (from `hardware/CONNECTORS.md` and the existing
`.scad` files) or deliberately derived, and should be reproduced exactly.
The *shapes* in the three.js model are representative primitives:
fillets, chamfers, draft, clip compliance and print tolerances are the
implementer's job. Anything marked **MEASURE ME** is an unresolved
placeholder — do not treat it as final (see "Open measurements").

## Coordinate system

Right-handed, millimetres, matching both the viewer and the `.scad`:

- **+x = fore** (toward the connector nose / front wall). `front_x = 88`,
  `rear_x = −120`.
- **z = across** the plinth, ±62 (`half_w`). Drawer centrelines at
  z = ±27.
- **y = up** in the viewer; in OpenSCAD the plan is 2-D in x/z-as-y and
  extruded in z. Keep the `.scad` convention: `plan()` is the x–y
  footprint, extruded upward.
- Origin is the plinth centre in plan, floor level in height.

## Assemblies

### 1. Body (single print)

Floor + shell merged into ONE printed body — 208 mm fits a 256 mm bed on
the diagonal. Keep the `floor`/`shell` part split in the `part` selector
only as a fallback for small printers.

| Value | mm |
|---|---|
| H | 38 |
| floor_h | 2.5 |
| deck_t / lid_t | 2.4 |
| plan | hull of Ø16 corner circles: rear pair at x = −112, z = ±34; front pair at x = 80, z = ±54 (slim delta, 208 × 124) |

Height budget (do not erode): 2.5 floor + 1.6 sled + **28.9 ESP32 on its
side** + 2.6 air + 2.4 deck = 38.0.

**Deck** — fixed, vented, spans 94 mm between tunnels; the arm adapter
bolts to it. Stiffened by four Ø10 M4 **boss columns** under the adapter
screw points (full-height columns, not bore-only — the earlier version
had a head recess with no material around it). Full-width cross-ribs are
not possible: they collide with the upright ESP32.

**Click-off base** — perimeter snap lip (`base_lip_h = 3`) plus 4
countersunk M3 **up through the floor** into shell-wall boss pads at
(−70, ±51.8) and (40, ±57.8). No side screws. The TPU feet keep the
heads clear. Tunnel mouths open at the bottom so the drawers ride the
base out; the base lip is notched at each mouth.

**Transom power wall rides the base** — the jack and both USB-C panel
extensions mount to a 3.2 mm wall rising from the floor at x ≈ −118.3
into a shell notch, capped by the chamber lid. Popping the base takes the
whole power end away wiring-intact. The HUSB238 / ORing shelf fuses to
this wall.

### 2. Drawers (2 prints + 2 sleds)

94 × 34 mm tunnels at z = ±27, mouths in the front wall, **lintel at deck
level** (the opening is not full height). Sleds bear directly on the
floor between solid floor-level side guides (`guide_w = 2.5`,
`guide_h = 5`) — no floating ledge rails. **Printed detents**: a 1.6 mm
guide bump against a 2.2 mm sled-edge scallop clicks each drawer home.
Zero-BOM; the magnet option is dropped.

- `sled_l = drw_l − 22` — the sled stops short of the tunnel rear to
  leave ~100 mm of service loop for the VIN/I²C tails.
- **ESP32 drawer**: board vertical in a cradle, **pins inboard**, USB-C
  at the red drawer face through a panel-extension window (flange
  **MEASURE ME**). Hole spacing 46.5 × 23.3.
- **PCA9685 drawer**: flat on 2.4 mm standoffs, holes 56.0 × 19.0, servo
  row outboard, I²C end aft toward the junction (chirality is fixed —
  mirroring it breaks the harness routing).
- Red faces with finger pulls.

### 3. Power chamber (aft, lidded)

66 × 52 mm at x = −85. Buck (65 × 48, holes 57 × 42 **MEASURE ME**) on a
slide-in sled; HUSB238 STEMMA QT (~22 × 18) and Pololu ORing pair
(~20 × 15) on the transom shelf. Snap lid, red coin-slot ballast caps
adjacent.

Power chain: 12 V barrel jack **and** USB-C PD (HUSB238, 20 V/100 W) both
feed the Pololu ORing ideal-diode pair (back-feed blocked) → 12–40 V buck
→ **6 V/10 A rail** → WAGO rails → six servo pairs direct; PCA9685 gets
logic only; ESP32 VIN off the same rail. **ADR-7 stands: 12 V/20 V never
reaches the servo rail. Verify 6.0 V at the buck before every first
connection.**

### 4. Servo junction tray (centreline)

40 × 66 mm at x = −30, between chamber and drawers, snap lid.

Two **separated** angled lanes with a wire gully between: **+ rail aft,
− rail fore**, `jt_lane_dx = 19`, leaning at `jt_angle = 40°`, levers up
— every clamp opens and re-wires with only the tray lid off. Each rail is
two bridged WAGO **221-415**s (body 18.6 × 30 × 8.3). Ten entries per
polarity = feed + jumper + 6 servos + 2 spare. Each 221-415 snaps into
**its own clip-fin pair**, so any single clamp pops off without
disturbing the rest.

Concept credit: pixelwave's WAGO junction box (MakerWorld #70798,
no-derivative licence). **The holder geometry here is our own** — do not
copy theirs; the clamps are standard parts.

Pigtails from both drawer tunnels enter through 19 × 14 service windows
in the dividing wall at x ≈ −7.5, z = ±27.

### 5. Coupler comb (v3.6) — the key serviceability part

A lift-out red rack that drops into grooves in the tray walls **above**
the WAGO lanes, at x = −30, y ≈ +20 (its floor plate spans 38 × 64 ×
3 mm). It is a real **Dupont connector rack**, not a cable clip.

Per channel, running aft → fore:

```
[end stop] [PCA-side MALE pigtail plug] --pins--> [ARM-side FEMALE plug] --> arm harness
```

- **Six channels, `PITCH = 9.6`**, clear width ~7.8 mm, formed by 7
  dividers (32 × 9 × 1.8) with **flared lead-ins** (5 × 5.5 × 3.4) at the
  fore mouth so a plug guides itself in.
- **Aft end stop** (3 × 9 × 64) at x = −48: the male PCA-side pigtail
  plug butts against it and is captive, so pulling the arm plug can never
  drag the drawer's pigtail out.
- Connector halves are standard 3-pin 2.54 mm Dupont: male housing ~9 ×
  6.2 × 7.4, female ~14.5 × 6.4 × 7.5 with a 1 mm key rib on top.
  Channel geometry must be re-cut once the real housings are measured
  (**MEASURE ME**).
- Leads are **colour-coded per pin**: signal (orange) / +6 V (red) / GND
  (black), 2.54 mm apart, both sides.
- **Index pips 1–6** moulded on the fore lip (1.4 × 1 × 1.4, spaced
  2.4 mm) — count the pips to identify the channel; no labels to wear
  off.
- **Hinged latch bar** closes over all six: beam 34 × 2.6 × 64 with a
  per-channel hold-down pad (30 × 1.6 × 7.4), a hook + barb at the fore
  end snapping over a catch ledge (2.5 × 2.5 × 14). Hinge is a **Ø3.4
  pinned knuckle set** — comb knuckles at z = −22, 0, +22; bar knuckles
  at z = ±11; pin on the axis at x = −47, y = +24.5.
  **OPEN DECISION:** keep the pinned hinge (one extra pin per comb, bar
  can't be lost) or make the bar a **separate clip-off piece** (no pin,
  simpler print, one more loose part). Decide before print prep.
- **Side tongues** (30 × 2.6 × 3 at z = ±33) ride the tray-wall grooves;
  finger lifts (6 × 3 × 9) at the fore corners. Lift the comb straight
  out with leads attached for full WAGO access underneath.

Service sequence this enables: flip the latch → six straight pulls →
arm harness free → PCA drawer slides out on its short pigtails through
the service window. No soldering, no reaching under the deck.

### 6. Harness egress (v3.7)

The 6 × 3-wire servo harness is the **only** thing that leaves the body.

- **Ø10.4 mm bore straight up through the junction tray lid at x = −17**
  (bore radius 5.4 in the lid outline), with an **aqua slit TPU 95A
  bushing** pressed in (Ø9.0 wire bore, OD 13.6, flange Ø19).
- x = −17 is chosen for clearance, not convenience: the arm **adapter
  plate's aft edge is at x = −8** and the arm's **aft bracket foot at
  x = −6**. The bore therefore rises into open air with nothing
  overhanging it. An exit further fore comes up underneath the arm's own
  foot.
- The bore sits **directly over the comb's fore lead-outs**, so the
  harness rises vertically with no sideways load on the connectors.
- **The lid U-notch is deleted** (it was v3.5): a plain bore is simpler
  and stronger. Lid removal is now: unplug the six comb joints, lift the
  lid clear.
- The **± motif window moved to the tray centreline, x = −30**, to clear
  the bore.

### 7. Arm adapter plate (separate print)

96 × 86 × 4 mm, red, centred at x = 40. The two stock bracket feet bolt
to it (M3, **MEASURE ME**); the adapter screws to the body with **4 × M4
from below** through the deck bosses at x = [16, 64] × z = [−30, 30]
(reachable via the drawer tunnels), into M4 heat-sets in the adapter.
Fit tests and future arms swap a 40-minute adapter print, not the
13-hour body.

### 8. Desk clamps (2 × 2 prints, optional)

Through-body slots at the **wide (arm) edge** — x = 76, z = ±56, slot
21 × 11 — so clamp force counters the tipping moment where it acts.
The clamp corners overhang the bench edge ~20 mm; the front feet sit
inboard at x = 56 to stay on the bench.

**Two prints per clamp** (nothing one-piece passes the 21 × 11 slot):
spine + T-head (28 wide) drops through from above, T-head bearing in a
deck recess; the jaw (34 wide) bolts to its lower end with 2 × M4 +
nuts. `clamp_ext` splices into the same joint for tops up to ~4".
Throat 52 mm clears a 2" top. M6 thumbscrew into a jaw heat-set nut with
a printed octagonal knob — no tools; TPU pressure pad on the tip.
Stowed: folded flat on the deck, arms inboard, T-heads at the flank
edges, clipped under printed stow posts + lips. Nothing below the floor,
so the base always sits flush.

### 9. Retention, feet, ballast

- **Lid clips**: PETG cantilevers on the lid undersides, 6 × 1.6 mm,
  0.8 mm nub, 4.5 mm drop, biting into shell-wall sockets. Print
  in-plane with the lid so they flex **along** layers, not across. Pop
  with a fingernail at the clip line.
- **Feet**: Ø22 × 4 TPU at (−106, ±26) and (56, ±50).
- **Ballast**: two lobes at the aft flanks (x = −76, z = ±40, 30 × 14),
  ~200 g steel shot, red coin-slot caps.

## Stability — read before shipping

Moments about the front foot line: a ~0.8 kg arm at full forward reach
puts ~180 kg·mm of overturning moment there; keel + 200 g ballast + arm
base return only ~75 kg·mm. **Free-standing, the arm will tip at full
forward reach.** In order: (1) clamps on — rigid, solved; (2) ~1 kg
ballast; (3) keep free-standing use to ≤ half reach at low speed.
The 124 mm width did not change forward tipping (length sets it); side
stability is fine.

## Print plan

- **Fit checks (PLA)**: 0.24 mm layers, 2 perimeters, 15 % infill.
  Verify the USB-C and jack cutouts, the bushing press fit, clip
  engagement, the ESP32 USB-C approach, the comb channel fit on real
  Dupont housings, and the proud-hardware reliefs before committing PETG.
- **Finals (PETG)**: 0.2 mm, 4–5 perimeters, ~25–30 %. Slow first layer.
  Body prints upright (deck-side down is impossible for a single body).
- **TPU 95A**: bushing, feet, clamp pads — 0.2 mm, slow.
- **Colours**: black body · white lids · red caps / drawers / comb / I-O
  panel / adapter · aqua TPU.
- The current viewer's parts panel enumerates **19 distinct parts across
  33 pieces** with material and orientation notes — use it as the print
  checklist (open `Arm board mounts.html`, Parts view).

## Bill of materials (adds beyond the existing arm kit)

| Part | Qty |
|---|---|
| Adafruit HUSB238 USB-C PD dummy, I²C-switchable, STEMMA QT | 1 |
| Pololu Power ORing Ideal Diode Pair, 4–60 V 6 A | 1 |
| WAGO 221-415 (5-way lever clamp) | 4 |
| Bridge jumper, 1.5 mm² × 30 mm (rail links) | 2 |
| Servo extension leads (coupler comb) | 6 |
| 12–40 V → 6 V/10 A buck (existing) | 1 |
| Panel-mount DC barrel jack, Ø11.2 | 1 |
| USB-C panel-mount extension, 200 mm | 2 |
| STEMMA QT cable (ESP32 → HUSB238) | 1 |
| M2.5 × 6 self-tap (board seats) | 12 |
| M3 heat-set + M3 × 10 (arm feet → adapter) | 4 + 4 |
| M4 heat-set + M4 × 16 (adapter → deck bosses) | 4 + 4 |
| M3 countersunk × 8 (base → shell bosses) | 4 |
| M4 × 12 + nut (clamp jaw splice; +4 with extensions) | 4 |
| M6 heat-set + M6 × 70 (clamp screws) | 2 + 2 |
| Ø3.4 pin, ~70 mm (comb latch hinge — if the pinned option is kept) | 1 |
| Steel shot ~200 g (up to 1 kg for free-standing use) | — |

## Work to do in the repo

`hardware/openscad/keel_base.scad` is at **v3.1**; the viewer is at
**v3.7**. In order:

1. **Coupler comb → connector rack.** The `.scad` still has the v3.1
   flat shelf (`comb_pitch = 9`, `comb_slot_w = 6.9`). Rebuild per §5:
   pitch 9.6, dividers with flared lead-ins, aft end stop, index pips,
   latch bar + hinge or clip, side tongues + finger lifts, and matching
   grooves in the tray walls.
2. **Harness egress → lid bore.** Delete `grom_notch_d` and the U-notch
   / rim relief; add the Ø10.4 bore in `keel_lid_junction()` at x = −17
   and a matching press-fit TPU bushing part. Move the ± motif to
   x = −30 (`keel_lid_junction_motif()` currently sits at `jt_x + 12`).
3. **Merge floor + shell into one body** (keep the split behind the
   `part` selector).
4. Confirm the deck boss columns are solid columns, not bare bores.
5. Resolve the latch-bar decision (§5) before generating STLs.
6. Take the **MEASURE ME** measurements below, then regenerate.

## Open measurements (blocking final print)

1. Bracket-foot hole positions on the real arm base (drives
   `arm_screw_dx` / `arm_screw_dz` and the proud-hardware reliefs at
   ±52).
2. Buck footprint and hole pattern of the actual clone
   (`buck_hole_dl/dw`, currently 57 × 42).
3. USB-C panel-extension flange size — drives both the transom cutouts
   and the ESP32 drawer-face window (`usbc_w/h`, currently 10.5 × 5.0).
4. Real servo-extension Dupont housing dimensions — sizes the comb
   channels.
5. Bench thickness at the intended desk (clamp throat / extension need).
6. Ballast choice: steel shot vs coins.

## Screenshots

`screenshots/` — captures of the v3.7 concept viewer, for orientation only
(the viewer is live in this bundle; orbit it rather than trusting a still).

| File | View |
|---|---|
| `01-overview.png` | assembled keel, arm stub + clamps on |
| `02-xray.png` | X-ray: drawers, WAGO lanes, buck sled, comb in place |
| `03-service-explode.png` | service explode: lids off, comb and latch bar lifted |
| `04-coupler-comb.png` | comb detail — six channels, Dupont pairs, latch bar open, TPU bushing above the lid bore |
| `05-printed-parts.png` | printed-parts layout, labelled with material + orientation |

## Files in this bundle

| File | What it is |
|---|---|
| `Arm board mounts.html` | interactive concept viewer (open in a browser) |
| `mounts.js` | the v3.7 three.js concept model — geometry, comb detail view, parts panel copy |
| `parts-view.js` | printed-parts panel |
| `three-d-stage.js` | viewer shell (renderer, lighting, orbit, OBJ/GLB export) |
| `openscad/keel_base.scad` | **the real source** (v3.1 — bring to v3.7) |
| `openscad/board_card.scad`, `openscad/buck_tap.scad` | archived alternative concepts, superseded |
| `docs/board-mount-concepts.md` | design rationale, layout table, power chain, print plan |
| `docs/design-review.md` | honest review with ✓/⚠/✗ verdicts and the v3.1–v3.5 change log |
| `screenshots/*.png` | viewer captures (see above) |
| `github.md` | repo binding: `jsamuel1/6dof-fun`, `main`, `hardware/`, last sync, screen map |

Note that `docs/board-mount-concepts.md` and `docs/design-review.md`
describe the v3.5 U-notch egress. **This README (v3.7) supersedes them**
on the egress and comb sections; they remain correct on everything else.
