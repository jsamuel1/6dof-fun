// =====================================================================
// pi4_case.scad — protective perforated case for the Raspberry Pi 4B.
//
// Two printed parts (export with -D 'part="base"' / -D 'part="lid"'):
//   base — full-height walls, punch-hole ventilation, port cutouts
//          (open-topped: the lid closes them, so nothing bridges),
//          M2.5 standoffs on the Pi's 58 x 49 pattern.
//   lid  — snap-fit skirt (ramped bumps click into wall windows),
//          fine punch-hole field across the top;
//          the holes SKIP a pixel-art silhouette of a robot arm holding
//          a raspberry, so the artwork appears as solid material in a
//          perforated field (ventilation + decoration, no tiny bridges).
//
// Print: PETG final (PLA fit check), 4 perimeters, ~30% infill,
// holes-down not required — both parts print flat, no supports.
// =====================================================================

include <common_params.scad>

part = "base";   // "base" | "lid" | "art" | "feet" | "both" (preview)
//
// Two-colour printing: export "lid" and "art" separately; in Bambu
// Studio import both STLs as parts of ONE object and assign a PETG
// colour to each. The art body fills a through-cut in the lid, so the
// motif shows on both faces. "feet" prints 4 press-fit bumpers in
// TPU 95A for the base's corner floor holes.

// --- Raspberry Pi 4B PCB -------------------------------------------------
pi_pcb_l      = 85;
pi_pcb_w      = 56;
pi_hole_dx    = 58;
pi_hole_dy    = 49;
pi_hole_off   = 3.5;
pi_standoff_h = 6;      // SD body + solder clearance under the PCB
pcb_t         = 1.6;

// --- Case body -----------------------------------------------------------
inner_h   = 24;          // floor top -> lid underside; one punch row lower
                         // than v1 (28) — the USB stack pokes out the open
                         // end cutout, so the lid only needs to clear its top
case_l    = pi_pcb_l + 2 * (wall_t + fit_clearance);
case_w    = pi_pcb_w + 2 * (wall_t + fit_clearance);
wall_h    = floor_t + inner_h;
pcb_top_z = floor_t + pi_standoff_h + pcb_t;

// --- Snap-fit lid --------------------------------------------------------
// v1's friction skirt wouldn't stay down. The lid now carries ramped
// snap bumps on the skirt that click into windows through the walls:
// two on the GPIO-side wall, one on the port-side wall past the port
// opening, one on the SD end. Press a fingernail into a window to pop
// the lid off.
snap_z_c    = wall_h - 3.8;   // window/bump centre height
snap_win_w  = 9;   snap_win_h  = 2.6;
snap_bump_w = 8;   snap_bump_h = 2.1;   snap_bump_p = 1.0;  // proudness
snap_xs_far = [case_l * 0.3, case_l * 0.7];   // GPIO-side wall (y = max)
snap_x_near = 75;             // port-side wall, clear of the port opening
snap_y_end  = case_w / 2;     // SD end wall (x = 0)

// --- Punch-hole pattern --------------------------------------------------
punch_d     = 2.2;      // "fine" holes
punch_pitch = 4.0;      // grid pitch, offset alternate rows (hex-ish)

// --- Lid -----------------------------------------------------------------
lid_t        = 2.0;
skirt_h      = 7;
skirt_t      = 1.6;
lid_margin   = 4.5;     // solid border before the hole field starts
art_pitch    = 3.2;     // artwork/vent grid pitch on the lid
art_hole_d   = 2.0;

// Pixel art motif shared with the electronics spine lid.
include <art_motif.scad>
art = art_motif;
art_rows = art_motif_rows;
art_cols = art_motif_cols;

// =====================================================================
// Base
// =====================================================================
module wall_punches() {
    // punch the two long walls with horizontal holes (3 rows for the
    // lower case); the top row skips around the snap windows
    for (zr = [0 : 2])
        for (xi = [0 : 17]) {
            x = 8 + xi * punch_pitch + (zr % 2 == 0 ? 0 : punch_pitch / 2);
            z = 13 + zr * punch_pitch;
            near_snap = zr == 2 &&
                (abs(x - snap_x_near) < 7 ||
                 abs(x - snap_xs_far[0]) < 7 || abs(x - snap_xs_far[1]) < 7);
            if (x < case_l - 8 && !near_snap) {
                for (y = [-0.1, case_w - wall_t - 0.1])
                    translate([x, y, z])
                        rotate([-90, 0, 0])
                            cylinder(h = wall_t + 0.2, d = punch_d);
            }
        }
}

module snap_windows() {
    // catch windows for the lid's snap bumps, through each wall
    for (sx = snap_xs_far)   // GPIO-side wall
        translate([sx - snap_win_w / 2, case_w - wall_t - 0.1,
                   snap_z_c - snap_win_h / 2])
            cube([snap_win_w, wall_t + 0.2, snap_win_h]);
    translate([snap_x_near - snap_win_w / 2, -0.1,   // port-side wall
               snap_z_c - snap_win_h / 2])
        cube([snap_win_w, wall_t + 0.2, snap_win_h]);
    translate([-0.1, snap_y_end - snap_win_w / 2,    // SD end wall
               snap_z_c - snap_win_h / 2])
        cube([wall_t + 0.2, snap_win_w, snap_win_h]);
}

module base() {
    difference() {
        union() {
            rounded_plate(case_l, case_w, floor_t);
            // walls
            difference() {
                rounded_plate(case_l, case_w, wall_h);
                translate([wall_t, wall_t, -0.1])
                    cube([case_l - 2 * wall_t, case_w - 2 * wall_t,
                          wall_h + 0.2]);
            }
            // Pi standoffs
            for (px = [0, 1], py = [0, 1])
                translate([wall_t + fit_clearance + pi_hole_off + px * pi_hole_dx,
                           wall_t + fit_clearance + pi_hole_off + py * pi_hole_dy,
                           floor_t])
                    standoff(pi_standoff_h, m25_pilot_d);
        }

        // floor vents (slot grid, same family as the trays)
        for (row = [0 : 4], col = [0 : 2])
            translate([case_l * 0.24 + col * (vent_slot_pitch + 6),
                       case_w * 0.30 + row * vent_row_pitch, 0])
                vent_slot(vent_slot_pitch, vent_slot_w, floor_t);

        // corner holes for the TPU 95A press-fit feet
        for (px = [0, 1], py = [0, 1])
            translate([foot_inset + px * (case_l - 2 * foot_inset),
                       foot_inset + py * (case_w - 2 * foot_inset), -0.1])
                cylinder(h = floor_t + 0.2, d = foot_hole_d);

        // USB / Ethernet end: open from just under PCB top to the rim
        translate([case_l - wall_t - 0.1, wall_t + 2, pcb_top_z - 3])
            cube([wall_t + 0.2, case_w - 2 * wall_t - 4, wall_h]);

        // USB-C + 2x micro-HDMI + audio (long side, y = 0): open-topped
        // to the rim — no bridge to print, the lid closes the top, and
        // the GPIO jumper wires exit over the ports through this same
        // opening (no separate slot on the GPIO side any more)
        translate([wall_t + fit_clearance + 4, -0.1, pcb_top_z - 1.5])
            cube([56, wall_t + 0.2, wall_h]);

        // SD end (x = 0): slot at floor level, card sits under the PCB
        translate([-0.1, case_w / 2 - 8, floor_t + 1])
            cube([wall_t + 0.2, 16, 5]);

        wall_punches();
        snap_windows();
    }
}

// =====================================================================
// Artwork body — the '#' cells extruded to full lid thickness. Printed
// in the second colour; the lid gets a matching through-cut. Cells are
// merged squares so each motif island is one solid piece; islands fuse
// to the surrounding lid at their vertical walls during the print.
// =====================================================================
module art_body(sym = "*") {
    // sym "A" = arm group, "B" = berry, "*" = both (through-cut shape)
    art_w = art_cols * art_pitch;
    art_h = art_rows * art_pitch;
    for (iy = [0 : art_rows - 1], ix = [0 : art_cols - 1])
        if (art[iy][ix] != "." &&
            (sym == "*" || art[iy][ix] == sym))
            translate([(case_l - art_w) / 2 + ix * art_pitch - 0.005,
                       (case_w - art_h) / 2 + (art_rows - 1 - iy) * art_pitch - 0.005,
                       0])
                cube([art_pitch + 0.01, art_pitch + 0.01, lid_t]);
}

// =====================================================================
// TPU 95A feet — press-fit bumpers for the base's corner floor holes.
// Stem is 0.2 over the hole; TPU squishes in and stays put.
// =====================================================================
foot_hole_d = 3.2;   // matching holes added in the base floor corners
foot_inset  = 6.5;   // hole centre inset from the case corner

module foot() {
    cylinder(h = 3, d1 = 9, d2 = 7);              // dome pad
    translate([0, 0, 3]) cylinder(h = floor_t + 1.2, d = foot_hole_d + 0.2);
    translate([0, 0, 3 + floor_t + 1.2])
        cylinder(h = 1, d1 = foot_hole_d + 1.4, d2 = foot_hole_d - 0.6);  // snap barb
}

module feet() {
    for (px = [0, 1], py = [0, 1])
        translate([px * 14, py * 14, 0]) foot();
}

// =====================================================================
// Lid
// =====================================================================
// Ramped snap bump, built for a wall along y = 0: sits on the skirt's
// outer face, protrudes -y, ramp below (cams over the rim as the lid
// presses on), square catch ledge on top (resists pull-off).
module snap_bump() {
    hull() {
        translate([-snap_bump_w / 2, 0, -snap_bump_h / 2])
            cube([snap_bump_w, 0.1, snap_bump_h]);
        translate([-snap_bump_w / 2, -snap_bump_p, snap_bump_h / 2 - 0.7])
            cube([snap_bump_w, 0.1, 0.7]);
    }
}

module lid() {
    art_w = art_cols * art_pitch;
    art_h = art_rows * art_pitch;
    bump_z = snap_z_c - wall_h;   // lid plate underside sits on the rim
    difference() {
        union() {
            rounded_plate(case_l, case_w, lid_t);
            // locating skirt, sits inside the walls
            difference() {
                translate([wall_t + fit_clearance, wall_t + fit_clearance, -skirt_h])
                    rounded_plate(case_l - 2 * (wall_t + fit_clearance),
                                  case_w - 2 * (wall_t + fit_clearance),
                                  skirt_h, corner_r - 1);
                translate([wall_t + fit_clearance + skirt_t,
                           wall_t + fit_clearance + skirt_t, -skirt_h - 0.1])
                    rounded_plate(case_l - 2 * (wall_t + fit_clearance + skirt_t),
                                  case_w - 2 * (wall_t + fit_clearance + skirt_t),
                                  skirt_h + 0.2, corner_r - 1);
            }
            // snap bumps, mirroring the base's windows
            translate([snap_x_near, wall_t + fit_clearance, bump_z])
                snap_bump();                                  // port side
            for (sx = snap_xs_far)
                translate([sx, case_w - wall_t - fit_clearance, bump_z])
                    rotate([0, 0, 180]) snap_bump();          // GPIO side
            translate([wall_t + fit_clearance, snap_y_end, bump_z])
                rotate([0, 0, -90]) snap_bump();              // SD end
        }
        // skirt relief over the base's rim-reaching openings — designed
        // in this time instead of hand-cut: the USB/Ethernet stack and
        // the port-side opening (ports + GPIO wire exit) pass under the
        // lid plate with no skirt in the way
        translate([case_l - wall_t - fit_clearance - skirt_t - 0.1,
                   wall_t + 2, -skirt_h - 0.1])
            cube([skirt_t + wall_t, case_w - 2 * wall_t - 4, skirt_h + 0.1]);
        translate([wall_t + fit_clearance + 4, -0.1, -skirt_h - 0.1])
            cube([56, wall_t + fit_clearance + skirt_t + 0.2, skirt_h + 0.1]);
        // through-cut for the two-colour artwork body
        translate([0, 0, -0.1]) scale([1, 1, 1.2]) art_body();
        // hole field with the artwork left solid; art block centred
        for (iy = [0 : art_rows - 1], ix = [0 : art_cols - 1]) {
            px = (case_l - art_w) / 2 + (ix + 0.5) * art_pitch;
            py = (case_w - art_h) / 2 + (art_rows - 1 - iy + 0.5) * art_pitch;
            if (art[iy][ix] == ".")
                translate([px, py, -0.1])
                    cylinder(h = lid_t + 0.2, d = art_hole_d);
        }
        // border ring of holes outside the art block, same pitch
        for (iy = [-2, art_rows, art_rows + 1],
             ix = [-2 : art_cols + 1]) {
            px = (case_l - art_w) / 2 + (ix + 0.5) * art_pitch;
            py = (case_w - art_h) / 2 + (art_rows - 1 - iy + 0.5) * art_pitch;
            if (px > lid_margin && px < case_l - lid_margin &&
                py > lid_margin && py < case_w - lid_margin)
                translate([px, py, -0.1])
                    cylinder(h = lid_t + 0.2, d = art_hole_d);
        }
        for (iy = [-1 : art_rows],
             ix = [-2, -1, art_cols, art_cols + 1]) {
            px = (case_l - art_w) / 2 + (ix + 0.5) * art_pitch;
            py = (case_w - art_h) / 2 + (art_rows - 1 - iy + 0.5) * art_pitch;
            if (px > lid_margin && px < case_l - lid_margin &&
                py > lid_margin && py < case_w - lid_margin)
                translate([px, py, -0.1])
                    cylinder(h = lid_t + 0.2, d = art_hole_d);
        }
    }
}

// =====================================================================
// plate_dx/plate_dy: shift the emitted part on the print plate
// (used by the combined-project export; override with -D)
module to_print_orientation() {
    translate([0, 2 * case_w + 15, lid_t])
        rotate([180, 0, 0])
            translate([0, -case_w, 0])
                children();
}

plate_dx = 0;
plate_dy = 0;
translate([plate_dx, plate_dy, 0]) {
    if (part == "base") base();
    if (part == "lid") lid();
    if (part == "art_arm") art_body("A");
    if (part == "art_berry") art_body("B");
    if (part == "feet") feet();
    // plate-layout variants: pre-positioned for the Bambu project file AND
    // flipped into print orientation — lid top face on the plate, skirt
    // pointing up. Both colour bodies then share the same z=0..lid_t plane,
    // flat on the plate: no floating geometry, exact inlay registration.
    if (part == "lid_plate") to_print_orientation() lid();
    if (part == "art_arm_plate") to_print_orientation() art_body("A");
    if (part == "art_berry_plate") to_print_orientation() art_body("B");
    if (part == "both") {
        base();
        translate([0, case_w + 12, skirt_h]) lid();
        translate([0, case_w + 12, skirt_h]) color("white") art_body("A");
        translate([0, case_w + 12, skirt_h]) color("red") art_body("B");
    }
}
