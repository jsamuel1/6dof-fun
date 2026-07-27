// =====================================================================
// modular_boards_plate.scad — a plate for the downloaded modular
// mounting system (110 x 97 footprint, corner screw holes 100 x 80,
// ~19.4mm of height under the family's lid) carrying BOTH arm boards:
//
//   * PCA9685 (blue clone), servo headers + mid-board V+ terminal UP;
//     right-angle end headers overhang into free air at both ends (I2C
//     Dupont housing on the -x end, toward the open deck).
//   * ESP32 (30-pin devkit) FLIPPED, PINS UP — every pin jumper-usable
//     from above.
//
// Boards mount FLUSH on the 2mm deck — no standoffs. Each board's
// opening is its own footprint + 0.6mm/side, minus four teardrop pads
// around the screw holes (the only deck the board touches). Everything
// on the underside hangs through the opening:
//   * PCA solder tails (~2) reach exactly the plate's bottom plane;
//   * pad shapes verified against solder-side hardware: ESP32 corner
//     holes are 5.4 from the first pin joint (pad reach 3 + teardrop
//     runs OUTWARD to the frame corner); PCA right-angle header tails
//     at (29.5, 6.3) clear the (28, 9.5) pad by 0.5.
//   * ESP32 RF can / USB shell go ~1.2 BELOW the plate's bottom plane,
//     and a seated USB-C plug ~2.6 below — the plate needs free air
//     beneath (corner-post mounting), not a flat surface.
//
// The USB-C plug slot remains (the plug body crosses the deck plane);
// the old central wire window is gone — wires now drop through the
// board openings themselves.
//
// Heights above deck: board tops 1.6; PCA screw terminal ~11.6; seated
// servo plugs / jumper housings ~15.6 — everything clears the family's
// 19.4 lid line with 3.8mm to spare.
//
// M2.5 screws self-tap the 2mm deck only; add nuts underneath if a
// board ever works loose (it carries no load).
//
// Interface dims extracted from the donor plate mesh (proj.3mf):
// outline 110 x 97, corner holes D4 at (+-50, +-40).
// =====================================================================

include <common_params.scad>

plate_l = 110;   plate_w = 97;   plate_t = 2;

// board dims (local copies so this file stands alone; ruler-verified)
pca_hole_dl = 56;     pca_hole_dw = 19;
pca_pcb_l   = 62.5;   pca_pcb_w   = 25.4;
esp_hole_dl = 46.5;   esp_hole_dw = 23.3;
esp_pcb_l   = 52;     esp_pcb_w   = 28.3;

corner_hole_d = 4.1;
corner_hole_x = 50;   corner_hole_y = 40;
plate_r = 6;

pca_y  = 22;     // PCA9685 board centre offset from plate centre (+y)
esp_y  = -22;    // ESP32 board centre offset (-y)

// boards pushed toward +x: ESP32 antenna end 5 from the edge; PCA9685
// end held 8 back so its bare right-angle pins (~6 proud) stay on-plate
esp_cx = plate_l - 5 - esp_pcb_l / 2;    // 79
pca_cx = plate_l - 8 - pca_pcb_l / 2;    // 70.75

// board openings: footprint + clearance, minus the four screw pads
win_clear = 0.6;    // opening margin per side around the PCB outline
win_r     = 4;      // opening corner radius
pad_d     = 6;      // screw pad diameter (teardrops out to the frame)
pad_run   = 4;      // how far the teardrop's outer lobe sits past the hole

// USB-C deck slot: the ESP32's USB end faces x=0 (board end at x=53);
// the plug body crosses the deck plane, so keep a full-depth stadium
// under its seated position + drop-in (it merges into the ESP opening)
usb_slot_w   = 14;      // plug body 10.5 wide + slop
usb_slot_x0  = 28;      // outer end — drop-in room ahead of the port
usb_slot_x1  = 60;      // inner end — under the port shell

// footprint opening minus teardrop screw pads, extruded through the deck
module board_window(cx, cy, win_l, win_w, hole_dl, hole_dw) {
    translate([cx, cy, -0.1])
        linear_extrude(plate_t + 0.2)
            difference() {
                offset(r = win_r) offset(delta = -win_r)
                    square([win_l, win_w], center = true);
                for (px = [-1, 1], py = [-1, 1])
                    hull() {
                        translate([px * hole_dl / 2, py * hole_dw / 2])
                            circle(d = pad_d);
                        translate([px * (hole_dl / 2 + pad_run),
                                   py * (hole_dw / 2 + pad_run)])
                            circle(d = pad_d);
                    }
            }
}

difference() {
    rounded_plate(plate_l, plate_w, plate_t, plate_r);
    // family corner screw holes
    for (px = [-1, 1], py = [-1, 1])
        translate([plate_l / 2 + px * corner_hole_x,
                   plate_w / 2 + py * corner_hole_y, -0.1])
            cylinder(h = plate_t + 0.2, d = corner_hole_d);
    // USB-C plug slot (closed stadium)
    translate([(usb_slot_x0 + usb_slot_x1) / 2, plate_w / 2 + esp_y, 0])
        vent_slot(usb_slot_x1 - usb_slot_x0, usb_slot_w, plate_t);
    // full-footprint openings under each board
    board_window(pca_cx, plate_w / 2 + pca_y,
                 pca_pcb_l + 2 * win_clear, pca_pcb_w + 2 * win_clear,
                 pca_hole_dl, pca_hole_dw);
    board_window(esp_cx, plate_w / 2 + esp_y,
                 esp_pcb_l + 2 * win_clear, esp_pcb_w + 2 * win_clear,
                 esp_hole_dl, esp_hole_dw);
    // board screw pilots, self-tapping through the flush deck pads
    for (bd = [[pca_cx, pca_y, pca_hole_dl, pca_hole_dw],
               [esp_cx, esp_y, esp_hole_dl, esp_hole_dw]],
         px = [-1, 1], py = [-1, 1])
        translate([bd[0] + px * bd[2] / 2,
                   plate_w / 2 + bd[1] + py * bd[3] / 2, -0.1])
            cylinder(h = plate_t + 0.2, d = m25_pilot_d);
}
