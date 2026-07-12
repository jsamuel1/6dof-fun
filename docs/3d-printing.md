# 3D Printing the Board Mounts

Custom enclosures mount the ESP32 and PCA9685 to the arm's existing metal
brackets. The designs are parametric OpenSCAD sources in `hardware/openscad/`;
you export STLs into `hardware/stl/` yourself after setting the measured
parameters (the bracket hole spacing is a measured input, so no
one-size-fits-all STL is committed).

## Workflow

### 1. Measure the bracket holes

The mounts bolt onto the arm's existing metal brackets, and hole spacing is a
**measured input, not a preset** — measure before printing anything:

- Center-to-center spacing of the bracket holes (calipers).
- Hole diameter (and the screw size you'll use).
- Bracket thickness and any clearance constraints around the mounting spot
  (servo horns, wiring paths).

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
