# Board mounts — the KEEL (selected)

The `electronics_spine` (165 × 46 × 24 on the arm) is replaced by the
**Keel**: an integrated base plinth the arm bolts onto. Boards, the full
power chain and ballast all live under the arm — nothing is added to the
motion envelope. Sources: `hardware/openscad/keel_base.scad`. Interactive
model: `Arm board mounts.html` (concepts B "Card" and C "Tap" remain in
the viewer as archive; C is superseded — the buck now lives in the Keel).

Every dimension below is measured (CONNECTORS.md, the existing `.scad`
files) or derived. Anything marked **MEASURE ME** is a placeholder.

---

## Layout (v3.1 — drawers under the arm)

**208 × 124 × 38 mm** (+4 mm TPU feet) · black PETG body, white lids,
red caps/drawers/comb/I-O panel, aqua TPU feet + grommet.

The space directly below the arm is the electronics bay: both logic
boards ride **slide-out drawers** that exit the front wall between
floor-level guides — red faces with finger pulls, printed detents click
them home; no lid access needed under the arm.
Width drops 192 → 124 mm; height grows 28 → 38 mm for the side-standing
ESP32.

| | |
|---|---|
| Height budget | 2.5 floor + 1.6 sled + **28.9 ESP32 on its side** + 2.6 air + 2.4 deck = 38 |
| Drawers | 94 × 34 tunnels at z ±27, under a fixed vented deck the arm feet bolt to; sleds bear on the floor between guide strips, printed detents click them home |
| ESP32 drawer | board vertical in a cradle, **pins inboard**, USB-C at the drawer face |
| PCA9685 drawer | flat on 2.4 mm standoffs (56 × 19), servo row outboard, I2C end aft (chirality fixed) |
| Power chamber | 66 × 52 aft: buck on a slide-in sled (holes 57 × 42 **MEASURE ME**) + HUSB238 + ORing pair on a shelf |
| Servo junction tray | 40 × 66 on the **centreline** between chamber and drawers: two separated angled lanes (+ aft, − fore), 2× bridged 221-415 per rail, levers up; snap lid |
| Coupler comb | flat shelf dropped into tray-wall grooves **above** the WAGO lanes: 6 servo-extension couplers lie in its channels — unplug here and the PCA drawer slides out on short pigtails; lift the comb out (leads attached) for WAGO access |
| Ballast | two lobes at the aft flanks, ~200 g steel shot, red coin-slot caps |
| Arm interface | **separately printed adapter plate** (96 × 86 × 4): bracket feet bolt to it (M3, **MEASURE ME**); adapter screws to the body with 4 × M4 from below via deck bosses — the boss columns double as deck stiffeners at the foot rows; fit-tests / future arms swap the adapter, not the body |
| Anchoring | two through-body edge clamps at the wide (arm) edge (below); no screw ears |
| Base fastening | click-off floor: perimeter snap lip + **4 countersunk M3 from below** into shell-wall bosses; the **transom power wall rides the base** (jack + USB-C extensions come away wiring-intact); tunnel mouths open at the bottom |

## Power

Dual inlet on the transom, either-or (or both — back-feed is blocked):

```
12 V barrel jack ──┐
                   ├─ Pololu Power ORing Ideal Diode Pair (4–60 V, 6 A)
USB-C PD ── HUSB238┘            │
   (20 V, 100 W charger)        ▼
                        12–40 V buck → 6 V/10 A rail
                                │
              PCA9685 V+ ◄─(logic only)  └──────► ESP32 VIN
                                │
                     WAGO 221-415 junction rails (+ / −)
                                │
                     6 × servo power pairs (direct)
```

- The transom power wall is **part of the click-off base** (v3.2): jack +
  both USB-C panel extensions come away with the floor, wiring intact.
- The HUSB238 STEMMA QT is I2C-switchable — the ESP32 can query/set PD
  voltage on the same bus it already runs to the PCA9685.
- PD caveat: chargers enforce current limits hard. A genuine 100 W GaN
  charger rides out multi-servo transients; a 60 W one will brown out.
  The 12 V/10 A brick remains the robust option; PD is the portable one.
- Second USB-C on the transom = ESP32 flash/service port only.
- ADR-7 stands: 12 V/20 V never reaches the servo rail; verify 6.0 V at
  the buck before every first connection.

## Servo power junctions

Servo +/− comes off **two separated WAGO rails in their own lanes**,
pixelwave-style: + rail on the inboard lane, − rail on the outboard lane,
a wire gully between. Each rail is two bridged **221-415s** leaning at
≈40° with levers up — **every clamp opens, closes and re-wires with just
the tray lid off**. Not the PCA9685's V+ terminal: six servos' stall
current never touches the PCA traces; its header carries **signal only**
(single-pin Dupont per channel). Per rail: 10 entries = feed + jumper +
6 servos, 2 spare. Grounds stay common through the − rail back to the
buck. Concept borrowed from pixelwave's Wago junction box (MakerWorld
#70798, no-derivative license) — the holder geometry here is our own;
the clamps are standard parts. Each 221-415 snaps into **its own
clip-fin pair** on the angled rail, so any single clamp pops off without
disturbing the rest (v3.3).

## Cable routing

Everything but the servo harness stays inside, running along the tunnel
and tray corners through floor-level wall pass-throughs (v3.1 deleted the
floor raceways — 1.5 mm was too shallow to matter and 4 mm can't live in a
2.5 mm floor; the click-off base opens every run from below anyway):

- chamber → junction tray: 6 V feed (16 AWG pair)
- junction tray → drawers: VIN pair via pass-through; servo pigtails via
  the widened PCA-side service window (19 × 14)
- ESP32 drawer → PCA drawer: I2C hookup (3V3/GND/SDA/SCL), around the
  drawer tails
- PCA drawer / comb → centreline edge bushing at the junction-lid edge:
  power trunk + 6 signal leads

The 6 × 3-wire servo harness is the only exit (v3.5): up through the
junction tray to a **TPU 95A edge bushing on the centreline, at the
arm-side edge of the junction tray lid** — a U-notch in the lid plus a
relief in the shell rim, lined by the slit bushing (Ø9 wire bore) so the
cables never bear on a printed PETG edge — then up the arm. Unclip the
bushing and the lid lifts off past the harness.

## Retention

Lids snap down: PETG cantilever clips (6 × 1.6 mm, 0.8 mm nub, 4.5 mm
drop) on the lid undersides bite into wall sockets. No screws to lose;
pop with a fingernail at the clip line.

## Desk clamps (through-body, aft)

Two OPTIONAL C-clamps mount **through slots in the keel body** at the
WIDE edge — the arm end, opposite the connector nose — so the clamp
force counters the tipping moment where it acts. The keel's clamp
corners **overhang the bench edge ~20 mm** (the front feet sit inboard,
still on the bench): the T-head bears in a deck recess, the spine drops
through the slot past the edge, and the **jaw + thumbscrew reach back
inboard under the benchtop**, clamping the keel onto the bench it sits
on. **Install** (v3.4 — the clamp is two prints; nothing one-piece fits
the 21 × 11 slot): drop the spine + T-head through the slot from above,
then bolt the jaw to its lower end with **2× M4 + nuts** — the extension
splices into the same joint for thick tops. Hand-tightened: M6
thumbscrew in a jaw heat-set nut with a printed octagonal knob — no
tools; TPU pressure pad on the tip. Throat clears a 2" top; `clamp_ext`
splices between spine and jaw (2× M4 each end) for tops up to ~4". When
off, the clamps **fold flat on the deck, arms inboard**, T-heads at the
flank edges, clipped under printed stow posts — nothing below the floor, so the base always sits flush.

## BOM (adds)

| Part | Qty |
|---|---|
| Adafruit HUSB238 USB-C PD dummy, I2C-switchable, STEMMA QT | 1 |
| Pololu Power ORing Ideal Diode Pair, 4–60 V 6 A | 1 |
| WAGO 221-415 (5-way lever clamp) | 4 |
| Bridge jumpers, 1.5 mm² × 30 mm (rail links) | 2 |
| Servo extension leads (coupler comb) | 6 |
| 12–40 V → 6 V/10 A buck (existing) | 1 |
| Panel-mount DC barrel jack, Ø11.2 | 1 |
| USB-C panel-mount extension | 2 |
| M2.5 self-tap screws (board seats) | 12 |
| M4 × 12 + nuts (clamp jaw splice; +4 with extensions) | 4 |
| M6 heat-set nuts + M6 × 60 screws (clamps) | 2 + 2 |

## Print plan

Repo rules: print flat as modelled, no supports.

- **Fit checks (PLA):** 0.24 mm, 2 perimeters, 15 %. Verify the USB-C and
  jack cutouts, the edge-bushing press fit, clip engagement, the ESP32 USB-C
  approach, and the proud-hardware reliefs before PETG.
- **Finals (PETG):** 0.2 mm, 4 perimeters, ~30 %. Slow first layer; clips
  print in-plane with the lid so they flex along layers, not across.
- **Edge bushing + feet: TPU 95A**, 0.2 mm layers, slow.
- **Colours:** black body · white lids · red caps/motifs/I-O panel · aqua TPU.

## Open questions before final print

1. Bracket geometry in the model is representative — confirm proud-hardware
   positions (±52) and base-plate hole locations. **MEASURE ME**
2. Buck footprint/hole pattern of the actual clone. **MEASURE ME**
3. USB-C panel-extension flange sizes drive the transom cutouts AND the
   ESP32 drawer-face window. **MEASURE ME**
4. Servo-extension coupler body sizes the comb channels. **MEASURE ME**
5. Ballast: steel shot vs coins.
