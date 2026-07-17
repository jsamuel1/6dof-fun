# 3D Printing the Board Mounts

Custom enclosures mount the ESP32 and PCA9685 to the arm's existing metal
brackets. The designs are parametric OpenSCAD sources in `hardware/openscad/`;
you export STLs into `hardware/stl/` yourself after setting the measured
parameters (the bracket hole spacing is a measured input, so no
one-size-fits-all STL is committed).

## Mounting anatomy

The printed "electronics spine" (`hardware/openscad/electronics_spine.scad`)
bolts to the arm's black metal base plates — the folded U-channel bracket at the
arm's foot. Seen face-on, each plate face carries a repeating,
left-right-symmetric hole pattern: paired small holes flanking larger bores,
with a circular bolt-circle around a central bore where a servo boss sits. The
evenly spaced small-hole pairs are the features the mounts' M3 "ear" pairs
(nominally 18 mm center-to-center) bolt through, so the printed part hangs off
the existing plate without new drilling.

<figure markdown>
  ![Face-on view of the arm's black metal base plate showing its hole pattern](img/bracket-hole-pattern-face-on.jpg){ width="600" }
  <figcaption>Face-on view of the arm's black metal U-channel base plate. The hole pattern is what the printed mount's 18&nbsp;mm M3 ear pairs bolt into: note the horizontally paired small holes at the corners and the central bolt-circle around a servo bore. Confirm the actual pair spacing with the <a href="#1b-print-the-spacing-test-plate-first">test plate</a> before committing a mount — these photos show layout, not measurements.</figcaption>
</figure>

<figure markdown>
  ![Closer face-on view of the base plate hole clusters](img/bracket-hole-pattern-detail.jpg){ width="600" }
  <figcaption>A second face-on angle of the same plate. The corner clusters each pair two small M3-size holes around a larger bore, and the pattern mirrors left-to-right and repeats on the folded lower face — the symmetry the mount's ear pairs register against.</figcaption>
</figure>

## Workflow

### 1. Measure the bracket holes

The mounts bolt onto the arm's existing metal brackets, and hole spacing is a
**measured input, not a preset** — measure before printing anything:

- Center-to-center spacing of the bracket holes (calipers).
- Hole diameter (and the screw size you'll use).
- Bracket thickness and any clearance constraints around the mounting spot
  (servo horns, wiring paths).

<figure markdown>
  ![A metal servo bracket measured against a ruler](img/bracket-measurement.jpg){ width="600" }
  <figcaption>The arm's existing metal servo bracket alongside a ruler. A quick ruler read gets you in the ballpark; use calipers on the actual hole centers and diameters for the OpenSCAD parameters.</figcaption>
</figure>

Also measure the footprint of the boards the mount will hold — the ESP32 dev
board and the PCA9685 driver — so the pocket and standoffs fit:

<figure markdown>
  ![ESP32 and PCA9685 boards next to a centimetre ruler](img/board-footprint-measurement.jpg){ width="600" }
  <figcaption>The ESP32 dev board (left) and PCA9685 servo driver (right) against a centimetre ruler — a footprint reference for sizing the mount pockets and mounting-hole positions.</figcaption>
</figure>

### 1b. Print the spacing test plate first

Ruler measurements are ballpark; screw holes are not. Before printing any
mount, print `hardware/stl/bracket_test_plate.stl` (source:
`hardware/openscad/bracket_test_plate.scad`) — a 5-minute PLA coupon with
labelled M3 hole pairs at 16/17/18/19/20 mm center-to-center. Hold it on the
bracket and find the row where two M3 screws drop through plate **and**
bracket freely, then set that spacing as `bracket_hole_spacing_mm` in
`hardware/openscad/common_params.scad`. If screws bind even on the correct
row, open up `bracket_screw_hole_d` instead — that's clearance, not spacing.

<figure markdown>
  ![Printed spacing test plate held against the metal servo bracket](img/test-plate-fit-check.jpg){ width="600" }
  <figcaption>The PLA test plate held up to the black aluminium multi-purpose servo bracket. Each labelled hole pair marks a candidate center-to-center spacing (16–20 mm); sight down each pair against the bracket's own mounting holes to find the row that lines up, then use that number as <code>bracket_hole_spacing_mm</code>.</figcaption>
</figure>

### 2. Set the variables and export

Open the relevant `.scad` file from `hardware/openscad/` in
[OpenSCAD](https://openscad.org/) and set the parameters at the top of the
file (bracket hole spacing, hole diameter, board choice) to your measured
values. Preview (++f5++), render (++f6++), then export the STL (++f7++ or
**File → Export → Export as STL…**). Keep exported STLs in `hardware/stl/` so
the printed geometry stays reproducible.

### 3. Print: PLA first, then PETG

Print every new or re-parameterized design **in PLA first** as a fit check —
it's cheap and fast, and bracket measurements are usually off by a little on
the first try. Bolt the PLA prototype to the actual bracket, seat the board in
it, and check screw alignment, wire clearance, and USB-C access. Iterate the
`.scad` variables until it fits.

Only then print the final part in **PETG** — it tolerates heat and load far
better than PLA for a part living on a moving arm.

## Print settings (Bambu Lab P2S)

| Setting | PLA fit-check | PETG final |
|---|---|---|
| Purpose | dimension/fit verification | permanent mount |
| Walls / perimeters | default (2–3) | **4 or more** |
| Infill | ~15% | **~30%** |
| Layer height | 0.2mm | 0.2mm |
| Notes | any color, fastest profile is fine | dry filament helps PETG surface quality; slower speeds reduce stringing |

## Assembly

1. Bolt the PETG enclosure to the metal bracket using the measured holes.
2. Seat the board; route the I2C run and the thick converter → V+ wires so
   they cannot be snagged by arm motion (see
   [Install → Hardware](install/1-hardware.md) for the wiring rules).
3. Confirm USB-C (ESP32) and the V+ terminal block (PCA9685) stay accessible
   after mounting.

Add photos of your fit checks and final mounts to the [gallery](gallery.md).


## Enclosure print job (phase 2)

Ready-made Bambu Studio project: **`hardware/arm_electronics.3mf`** — one
plate carrying the Pi case (base + two-colour lid) and the electronics
spine (body + two-colour lid). Both lids print face-down with the shared
robot-arm-and-raspberry motif inlaid in filament 2. Configured for the
P2S: 0.4 nozzle, 0.20mm Standard, textured PEI plate, 2x PETG Basic —
map the two slots to your colours, slice, print. The TPU 95A feet
(`hardware/stl/pi4_case_feet.stl`) print as a separate job — TPU doesn't
co-plate with PETG.
