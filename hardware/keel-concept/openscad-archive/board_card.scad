// =====================================================================
// board_card.scad — Concept B "CARD": one slim vented card per board,
// bolted flat to a face of the arm's bent bracket leg. The board sits
// PARALLEL to the bracket so its 14 mm Dupont housings live inside the
// 19 mm cavity instead of setting the height of a box.
//
// Two cards, one on each face of the same leg, on the existing 18 mm M3
// pairs — nothing spans the frame seam and either card comes off alone.
//
// Parts (-D 'part="..."'):
//   "frame" | "backplate" | "cover" | "trim" | "outrigger" | "all"
// Board (-D 'board="..."'):  "esp32" | "pca9685"
//
// Print the frame on its back face, the plates flat. No supports.
// =====================================================================

include <common_params.scad>

part  = "all";
board = "pca9685";

T        = 19;    // cavity depth: 1.6 PCB + 14 Dupont + air
back_t   = 2.6;
cover_t  = 2.0;
trim_t   = 1.2;

// card half-length: the PCA9685 card is longer than the ESP32 card
half_l   = (board == "esp32") ? 35 : 42;
top_y    = 21;    // flange line, 5.5 below the bracket's top edge
bot_y    = -24;

// mounting: one 18 mm M3 pair; the arm's proud screws sit 52 mm out from
// the row centre, i.e. 27 mm from a card centred on its pair
mnt_dx     = bracket_hole_spacing_mm / 2;   // 9
mnt_y      = 15;
proud_dx   = 27;
proud_relief_d = 18;

esp_hole_dl = 46.5;  esp_hole_dw = 23.3;
pca_hole_dl = 56.0;  pca_hole_dw = 19.0;
hole_dl = (board == "esp32") ? esp_hole_dl : pca_hole_dl;
hole_dw = (board == "esp32") ? esp_hole_dw : pca_hole_dw;
seat_h  = 4.2;      // board face standoff off the backplate

// =====================================================================
// side elevation: flat flange on top, swept tail — hull of circles keeps
// it convex, printable and free of stress risers
module card_plan() {
    hull() {
        translate([-half_l + 4, top_y - 4])  circle(r = 4);
        translate([ half_l - 4, top_y - 4])  circle(r = 4);
        translate([ half_l - 12, bot_y + 12]) circle(r = 12);
        translate([-half_l + 14, bot_y + 12]) circle(r = 12);
    }
}
module rrect(l, w, r) offset(r = r) square([l - 2 * r, w - 2 * r], center = true);
module cavity() translate([-3, -3]) rrect(2 * half_l - 16, 32, 5);

module card_frame() {
    difference() {
        linear_extrude(T) card_plan();
        translate([0, 0, -0.1]) linear_extrude(T + 0.2) cavity();
        // cover rabbet
        translate([0, 0, T - cover_t - trim_t])
            linear_extrude(cover_t + trim_t + 0.1)
                difference() { card_plan(); offset(delta = -2.2) card_plan(); }
    }
    // board seats, standing off the backplate
    for (px = [-1, 1], pz = [-1, 1])
        translate([-3 + px * hole_dl / 2, -3 + pz * hole_dw / 2, 0])
            standoff(seat_h, m25_pilot_d);
}

module card_backplate() {
    difference() {
        linear_extrude(back_t) card_plan();
        // 18 mm M3 pair onto the bracket
        for (sx = [-1, 1])
            translate([sx * mnt_dx, mnt_y, -0.1])
                cylinder(h = back_t + 0.2, d = m3_free_d);
        // relief for the arm's proud assembly hardware
        for (sx = [-1, 1])
            translate([sx * proud_dx, mnt_y, -0.1])
                cylinder(h = back_t + 0.2, d = proud_relief_d);
        // servo-lead / cable exit, on the PCA9685's fixed servo-row side
        translate([half_l - 20, -14, 0]) vent_slot(16, 5, back_t);
        // floor vents
        for (c = [-2 : 2]) translate([c * 13, -6, 0]) vent_slot(8, 3, back_t);
    }
}

// four long louvres, not a dot field: open, quiet to print, easy to clean
module card_cover() {
    difference() {
        linear_extrude(cover_t) card_plan();
        for (r = [0 : 3])
            translate([-4, 8 - r * 9, 0]) vent_slot(2 * half_l - 30, 5, cover_t);
    }
}
module card_trim() {
    difference() {
        linear_extrude(trim_t) card_plan();
        translate([0, 0, -0.1]) linear_extrude(trim_t + 0.2)
            translate([-3, -3]) rrect(2 * half_l - 18, 34, 6);
    }
}

// ---------------------------------------------------------------------
// outrigger: bolts to a rear corner hole of the arm base plate and puts a
// TPU pad ~110 mm out. Two of them widen the rear footprint to ~220 mm.
// The right-hand one carries the XT60E-F on a flat vertical panel — no
// face of a card is wide enough for the 34 x 16 flange.
// ---------------------------------------------------------------------
outr_l = 92;  outr_w = 30;  outr_h = 6;  pad_d = 26;  pad_h = 5;
with_inlet_panel = true;
pwr_cut_w = 16.6;  pwr_cut_h = 13.0;  pwr_screw_p = 25.0;  pwr_screw_d = 2.05;

module outrigger() {
    difference() {
        union() {
            linear_extrude(outr_h) rrect(outr_l, outr_w, 14);
            translate([-8, 0]) linear_extrude(17) rrect(64, 13, 6);
            if (with_inlet_panel) {
                translate([-outr_l / 2 + 2, -13, 0]) cube([5, 26, 34]);
            }
        }
        translate([-34, 0, -0.1]) cylinder(h = 20, d = m3_free_d);
        translate([26, 0, -0.1]) linear_extrude(outr_h + 0.2) rrect(32, 14, 7);
        if (with_inlet_panel) {
            translate([-outr_l / 2 + 1, -pwr_cut_w / 2, 21 - pwr_cut_h / 2])
                cube([8, pwr_cut_w, pwr_cut_h]);
            for (sy = [-1, 1])
                translate([-outr_l / 2 + 1, sy * pwr_screw_p / 2, 21])
                    rotate([0, 90, 0]) cylinder(h = 8, d = pwr_screw_d);
        }
    }
}

// =====================================================================
if (part == "frame")      card_frame();
if (part == "backplate")  card_backplate();
if (part == "cover")      card_cover();
if (part == "trim")       card_trim();
if (part == "outrigger")  outrigger();
if (part == "all") {
    translate([0, 0, back_t]) card_frame();
    card_backplate();
    color("white") translate([0, 0, back_t + T - cover_t - trim_t]) card_cover();
    color("red")   translate([0, 0, back_t + T - trim_t]) card_trim();
    color("aqua")  translate([-8, bot_y - 1.3, back_t])
        cube([2 * half_l - 36, 2.6, T], center = false);
    translate([0, -70, 0]) outrigger();
}
