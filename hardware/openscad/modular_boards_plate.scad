// =====================================================================
// modular_boards_plate.scad — a plate for the downloaded modular
// mounting system (110 x 97 footprint, corner screw holes 100 x 80,
// ~19.4mm of height under the family's lid) carrying BOTH arm boards:
//
//   * PCA9685 (blue clone) on M2.5 standoffs, servo headers + mid-board
//     V+ terminal facing UP; right-angle end headers overhang the
//     standoffs into free air at both ends (I2C Dupont housing goes on
//     the -x end, toward the open deck — the +x end's bare pins stay
//     inside the plate outline).
//   * ESP32 (30-pin devkit) FLIPPED, PINS UP — every pin jumper-usable
//     from above; RF can, buttons and USB-C hang beneath the raised
//     board over a relief window cut through the deck.
//
// Both boards are pushed toward the +x end, leaving ~50mm of open deck
// at the x=0 end for the USB-C plug, its cable, and the I2C housing.
// The deck is 2mm — the plate carries no load, so thin + through-cuts
// is plenty (the family corner screws still clamp it flat).
//
// Height notes (deck = plate top): ESP32 pin tips 10.6; PCA servo pin
// tips 12.1; PCA screw terminal top ~14.1 — the tallest bare component,
// per "no taller than the screw-in connector". Seated servo plugs
// ~18.1 and seated jumper housings ~18.6: EVERYTHING now fits under
// the system's 19.4 lid line, connectors included.
//
// Standoff floors: PCA 2.5 (solder tails ~2); ESP32 3.0 — the tall
// underside features of the flipped board (RF can ~3.1, USB-C shell
// ~3.2) sit over the relief window / USB slot, and the low tactile
// buttons (~2-2.5) clear the deck beside the window. The USB-C plug
// body rides ~1.6 below deck top — still 0.4 above the plate's bottom
// plane, so nothing pokes below the plate.
//
// Interface dims extracted from the donor plate mesh (proj.3mf):
// outline 110 x 97, corner holes D4 at (+-50, +-40).
// =====================================================================

include <common_params.scad>

// rounded-rect through-window centred on (cx, cy)
module board_window(cx, cy, l, w) {
    translate([cx, cy, 0])
        hull()
            for (px = [-1, 1], py = [-1, 1])
                translate([px * (l / 2 - win_r), py * (w / 2 - win_r), -0.1])
                    cylinder(h = plate_t + 0.2, r = win_r);
}

plate_l = 110;   plate_w = 97;   plate_t = 2;

// board dims (local copies so this file stands alone; ruler-verified)
pca_hole_dl = 56;     pca_hole_dw = 19;     pca_pcb_l = 62.5;
esp_hole_dl = 46.5;   esp_hole_dw = 23.3;   esp_pcb_l = 52;
corner_hole_d = 4.1;
corner_hole_x = 50;   corner_hole_y = 40;
plate_r = 6;

pca_y  = 22;     // PCA9685 board centre offset from plate centre (+y)
esp_y  = -22;    // ESP32 board centre offset (-y)
esp_standoff_h = 3;     // buttons clear the deck; can/USB over the window
pca_standoff_h = 2.5;   // just solder-tail clearance

// boards pushed toward +x: ESP32 antenna end 5 from the edge; PCA9685
// end held 8 back so its bare right-angle pins (~6 proud) stay on-plate
esp_cx = plate_l - 5 - esp_pcb_l / 2;    // 79
pca_cx = plate_l - 8 - pca_pcb_l / 2;    // 70.75

// USB-C deck slot: the ESP32's USB end faces x=0 (board end at x=53);
// the plug body rides ~1.6 below deck top, so cut a full-depth stadium
// under its seated position + insertion drop-in. Closed at BOTH ends —
// running it to the plate edge would merge with the can window and
// leave the front strip a 100mm cantilever in 2mm PETG.
usb_slot_w   = 14;      // plug body 10.5 wide + slop
usb_slot_x0  = 28;      // outer end — drop-in room ahead of the port
usb_slot_x1  = 60;      // inner end — under the port shell

// full-open windows under each board: the whole area inside the screw
// pattern is cut away, leaving a ~1.5mm web to each standoff base (the
// standoffs must stay rooted to the deck — that web is the only limit).
// The ESP32's USB shell zone (outside its window, at the hole-row line)
// is covered by the USB slot instead.
pca_win_l = 47;   pca_win_w = 10;   // holes 56 x 19
esp_win_l = 37;   esp_win_w = 14;   // holes 46.5 x 23.3
win_r = 4;                          // window corner radius

difference() {
    union() {
        rounded_plate(plate_l, plate_w, plate_t, plate_r);
        // PCA9685 standoffs (56 x 19, M2.5)
        for (px = [-1, 1], py = [-1, 1])
            translate([pca_cx + px * pca_hole_dl / 2,
                       plate_w / 2 + pca_y + py * pca_hole_dw / 2, plate_t])
                standoff(pca_standoff_h, m25_pilot_d);
        // ESP32 corner standoffs (46.5 x 23.3, M2.5), board pins-UP
        for (px = [-1, 1], py = [-1, 1])
            translate([esp_cx + px * esp_hole_dl / 2,
                       plate_w / 2 + esp_y + py * esp_hole_dw / 2, plate_t])
                standoff(esp_standoff_h, m25_pilot_d);
    }
    // family corner screw holes
    for (px = [-1, 1], py = [-1, 1])
        translate([plate_l / 2 + px * corner_hole_x,
                   plate_w / 2 + py * corner_hole_y, -0.1])
            cylinder(h = plate_t + 0.2, d = corner_hole_d);
    // wire pass-through between the two boards
    translate([(pca_cx + esp_cx) / 2, plate_w / 2 + 1.5, 0])
        hull()
            for (ox = [-20, 20])
                translate([ox, 0, -0.1])
                    cylinder(h = plate_t + 0.2, d = 12);
    // USB-C plug slot (closed stadium)
    translate([(usb_slot_x0 + usb_slot_x1) / 2, plate_w / 2 + esp_y, 0])
        vent_slot(usb_slot_x1 - usb_slot_x0, usb_slot_w, plate_t);
    // full-open windows under each board (rounded rects inside the
    // standoff patterns)
    board_window(pca_cx, plate_w / 2 + pca_y, pca_win_l, pca_win_w);
    board_window(esp_cx, plate_w / 2 + esp_y, esp_win_l, esp_win_w);
}
