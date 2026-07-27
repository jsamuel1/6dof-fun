// =====================================================================
// buck_tap.scad — Concept C "TAP": a standalone pod for the 12V→6V
// buck-boost converter. The converter leaves the arm entirely and lives
// beside the 12 V supply, so its heat and the 12 V rail stay away from
// the logic boards and the servo harness (ADR-7's hard rule gets easier
// to keep: 12 V must never reach the servo rail).
//
// 12 V barrel jack in on the flat rear wall; 6 V out on a screw terminal
// to a male XT60 flying lead, which mates with the arm's panel XT60E-F.
//
// Parts (-D 'part="..."'): "floor" | "shell" | "lid" | "window" | "all"
// Print flat, no supports.
// =====================================================================

include <common_params.scad>

part = "all";

H       = 32;    // 3 floor + 5 standoff + 1.6 PCB + ~20 heatsink + lid
floor_h = 3;
lid_t   = 2.4;

// --- buck converter board (12–40 V in → 6 V/10 A, 60 W) ---------------
// *** MEASURE ME *** clone footprints vary; 65 x 48 is typical
buck_l = 65;  buck_w = 48;
buck_hole_dl = 57;  buck_hole_dw = 42;
seat_h = 5;

// --- plan: rounded pebble with a FLAT rear wall for the jack panel ----
rear_x = -48;  front_x = 48;  half_w = 40;
cavity_l = 72; cavity_w = 54;

// --- 12 V inlet: panel-mount DC barrel jack ---------------------------
jack_d   = 11.2;   // panel nut thread
jack_z   = floor_h + 12;

// --- 6 V output -------------------------------------------------------
out_w = 26;  out_h = 12;

feet = [[-38, -26], [-38, 26], [34, -22], [34, 22]];
foot_d = 18;  foot_h = 4;

// =====================================================================
module plan() {
    hull() {
        for (sy = [-1, 1]) {
            translate([rear_x + 4, sy * 32]) circle(r = 4);
            translate([-10, sy * (half_w - 4)]) circle(r = 4);
            translate([front_x - 14, sy * (half_w - 18)]) circle(r = 18);
        }
    }
}
module rrect(l, w, r) offset(r = r) square([l - 2 * r, w - 2 * r], center = true);

module tap_floor() {
    difference() {
        linear_extrude(floor_h) plan();
        // wide-open slotted floor: a straight-through draught over the fins
        for (r = [-2 : 2]) translate([0, r * 13, 0]) vent_slot(44, 3, floor_h);
        for (f = feet) translate([f[0], f[1], -0.1]) cylinder(h = 1.2, d = foot_d + 0.6);
    }
}

module tap_shell() {
    difference() {
        linear_extrude(H) plan();
        translate([-2, 0, floor_h]) linear_extrude(H) rrect(cavity_l, cavity_w, 6);
        translate([0, 0, H - lid_t]) linear_extrude(lid_t + 0.1)
            difference() { plan(); offset(delta = -2.4) plan(); }
        // 12 V barrel jack, on the flat rear wall
        translate([rear_x - 1, -18, jack_z]) rotate([0, 90, 0])
            cylinder(h = 10, d = jack_d);
        // 6 V output window
        translate([front_x - 3, -out_w / 2, floor_h + 2])
            cube([8, out_w, out_h]);
    }
    for (px = [-1, 1], pz = [-1, 1])
        translate([-2 + px * buck_hole_dl / 2, pz * buck_hole_dw / 2, floor_h])
            standoff(seat_h, m25_pilot_d);
}

// lid: a coarse hole field over the heatsink + a second-colour window
// over the setpoint trimpot — verify 6.0 V before every first connection
module tap_lid(window = true) {
    difference() {
        linear_extrude(lid_t) plan();
        for (c = [-3 : 3], r = [-2 : 2]) {
            x = -8 + c * 10;  y = r * 11 + (c % 2) * 5;
            if (abs(x) < 34 && abs(y) < 26)
                translate([x, y, -0.1]) cylinder(h = lid_t + 0.2, d = 6.2);
        }
        if (window)
            translate([32, 0, -0.1]) linear_extrude(lid_t + 0.2) rrect(20, 44, 3);
    }
}
module tap_window() translate([32, 0, 0]) linear_extrude(lid_t) rrect(19.4, 43.4, 3);

// =====================================================================
if (part == "floor")  tap_floor();
if (part == "shell")  tap_shell();
if (part == "lid")    tap_lid();
if (part == "window") tap_window();
if (part == "all") {
    tap_floor();
    tap_shell();
    translate([0, 0, H - lid_t]) {
        color("white") tap_lid();
        color("red")   tap_window();
    }
    color("aqua") for (f = feet)
        translate([f[0], f[1], -foot_h]) cylinder(h = foot_h, d = foot_d);
}
