# OpenSCAD Mount Designs

Parametric 3D-printable trays that mount the arm's electronics onto the
existing metal brackets:

| File | Part |
|---|---|
| `common_params.scad` | Shared dimensions and helper modules (bracket ears, standoffs, vents). Included by both mounts — **the bracket measurements live here.** |
| `esp32_mount.scad` | Open-top tray for the Elegoo ESP32 dev board (USB-C, 38-pin). Snap-in retention (these boards have no mounting holes), open USB-C slot, top access to pins/buttons. |
| `pca9685_mount.scad` | Tray for the PCA9685 16-channel servo driver. M2.5 screw standoffs on the standard 56 x 19 mm hole grid, open servo-header edge, notches for the V+ terminal wires and I2C headers. |

Both trays print flat, need no supports, and have ventilation slots in
the floor (the ESP32 tray also vents through its long walls).

## Opening the files

1. Install [OpenSCAD](https://openscad.org/downloads.html) (free,
   macOS/Windows/Linux). On macOS: `brew install --cask openscad`.
2. Open `esp32_mount.scad` or `pca9685_mount.scad` directly — each one
   `include`s `common_params.scad` automatically, so keep all three
   files in this directory.
3. Press **F5** for a fast preview while editing, **F6** for a full
   render (required before export).

## Measure these before printing finals

Everything is a named variable; the ones below are marked `MEASURE ME`
in the source. Edit the values in the file (or override at export time
with `-D`, see below).

| Variable | File | Default | What to measure |
|---|---|---|---|
| `bracket_hole_spacing_mm` | `common_params.scad` | **20 (placeholder!)** | Centre-to-centre distance between the two screw holes on the arm's metal bracket. The design echoes a console warning until you change it. |
| `bracket_screw_hole_d` | `common_params.scad` | 4.5 (M4 free fit) | Diameter of the bracket screws. Use 3.4 for M3, 5.5 for M5. |
| `esp32_pcb_l` / `esp32_pcb_w` | `esp32_mount.scad` | 52.0 / 28.9 | Your ESP32 PCB length and width — clone boards vary by a millimetre or two, and the snap fit is sized off these numbers. |
| `esp32_pin_protrusion` | `esp32_mount.scad` | 9.0 | How far the header pins stick out **below** the PCB underside. Sets the standoff height so the pins hang clear of the floor. |
| `pca_pcb_l` / `pca_pcb_w` / hole grid | `pca9685_mount.scad` | 62.5 / 25.4, 56 x 19 | Standard for Adafruit-format boards; just confirm your clone matches before printing. |

Also worth a sanity check: `fit_clearance` (0.25 mm per side) suits a
well-tuned printer; bump to 0.35 if your fit checks come out tight.

## Exporting STLs

GUI: open the file, edit the `MEASURE ME` values, press **F6** to
render, then **File → Export → Export as STL** into `../stl/`.

Command line (values can be overridden without editing the source):

```sh
openscad -o ../stl/esp32_mount.stl \
    -D 'bracket_hole_spacing_mm=32.5' \
    esp32_mount.scad

openscad -o ../stl/pca9685_mount.stl \
    -D 'bracket_hole_spacing_mm=32.5' \
    pca9685_mount.scad
```

(Replace `32.5` with the real measured spacing. On macOS the binary is
at `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD` if it isn't on
your `PATH`.)

## Print settings

Print both parts **flat as modeled** (floor on the bed). No supports
needed — every overhang is chamfered or bridges a short slot.

**Fit-check prototypes (PLA):**

- 0.2-0.28 mm layers, 2 perimeters, 15% infill — fast and cheap.
- Purpose: verify bracket hole spacing, PCB fit, USB-C slot alignment,
  and the ESP32 snap action before committing to PETG.

**Final parts (PETG):**

- 4+ perimeters, ~30% infill, 0.2 mm layers.
- PETG is the right material here: the ESP32 snap posts flex on every
  insertion (PLA can crack after a few cycles), and PETG tolerates the
  warmth of a working servo driver better.
- Slow the first layer and use a clean bed — the bracket ears take the
  screw load, so good layer adhesion at the base matters.

## Assembly

1. Screw each tray to the arm bracket through the two ears (tray first —
   easier than working around an installed PCB).
2. **PCA9685:** set the board on the four standoffs and drive M2.5
   screws into the printed pilot holes (they self-tap; no nuts needed).
3. **ESP32:** tilt the board, slide the USB-C end under the two fixed
   lips beside the USB slot, then press the antenna end down until it
   clicks past the two snap posts. To remove, push the posts outward
   through the openings in the antenna-end wall while lifting the board.
