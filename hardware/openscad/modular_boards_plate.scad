// =====================================================================
// modular_boards_plate.scad — a plate for the downloaded modular
// mounting system (110 x 97 x 5, corner screw holes 100 x 80, ~19.4mm
// of height under the family's lid) carrying BOTH arm boards:
//
//   * PCA9685 (blue clone) on M2.5 standoffs, servo headers + mid-board
//     V+ terminal facing UP; right-angle end headers overhang the
//     standoffs into free air at both ends.
//   * ESP32 (30-pin devkit) FLIPPED, PINS UP — every pin jumper-usable
//     from above; RF can and USB-C hang beneath the raised board, and
//     the USB-C plug approaches over the deck from the plate edge.
//
// Height notes (deck = plate top): ESP32 pin tips 13.1; PCA servo pins
// 14.6. With jumper housings / servo plugs seated the stacks reach
// ~20-21 — poke a touch past the system's 19.4 lid line, fine with the
// lid off or a vented lid.
//
// Interface dims extracted from the donor plate mesh (proj.3mf):
// outline 110 x 97 x 5, corner holes D4 at (+-50, +-40).
// =====================================================================

include <common_params.scad>

plate_l = 110;   plate_w = 97;   plate_t = 5;
corner_hole_d = 4.1;
corner_hole_x = 50;   corner_hole_y = 40;
plate_r = 6;

pca_y  = 22;     // PCA9685 board centre (servo edge toward +y rim)
esp_y  = -22;    // ESP32 board centre
esp_standoff_h = 5.5;   // flipped board: USB-C plug clears the deck
pca_standoff_h = 5;

difference() {
    union() {
        rounded_plate(plate_l, plate_w, plate_t, plate_r);
        // PCA9685 standoffs (56 x 19, M2.5)
        for (px = [-1, 1], py = [-1, 1])
            translate([plate_l / 2 + px * pca_hole_dl / 2,
                       plate_w / 2 + pca_y + py * pca_hole_dw / 2, plate_t])
                standoff(pca_standoff_h, m25_pilot_d);
        // ESP32 corner standoffs (46.5 x 23.3, M2.5), board pins-UP
        for (px = [-1, 1], py = [-1, 1])
            translate([plate_l / 2 + px * esp_hole_dl / 2,
                       plate_w / 2 + esp_y + py * esp_hole_dw / 2, plate_t])
                standoff(esp_standoff_h, m25_pilot_d);
    }
    // family corner screw holes
    for (px = [-1, 1], py = [-1, 1])
        translate([plate_l / 2 + px * corner_hole_x,
                   plate_w / 2 + py * corner_hole_y, -0.1])
            cylinder(h = plate_t + 0.2, d = corner_hole_d);
    // central window: wire pass-through between the two boards
    translate([plate_l / 2, plate_w / 2 + 1.5, 0])
        hull()
            for (ox = [-24, 24])
                translate([ox, 0, -0.1])
                    cylinder(h = plate_t + 0.2, d = 12);
    // vent/tie slots under each board
    for (sy = [pca_y, esp_y], sx = [-18, 0, 18])
        translate([plate_l / 2 + sx, plate_w / 2 + sy, 0])
            vent_slot(14, 4, plate_t);
}

// board dims come from electronics_spine.scad's world; keep local copies
// so this file stands alone if that file evolves
pca_hole_dl = 56;     pca_hole_dw = 19;
esp_hole_dl = 46.5;   esp_hole_dw = 23.3;   // ruler-verified 2026-07-18
