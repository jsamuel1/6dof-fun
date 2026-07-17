// =====================================================================
// common_params.scad
// Shared parameters and helper modules for the 6DOF robot arm
// electronics mounts (esp32_mount.scad and pca9685_mount.scad).
//
// Include from the mount files with:
//     include <common_params.scad>
//
// All dimensions are millimetres. Every value here is deliberately a
// named variable — override on the command line with -D or edit here.
// =====================================================================

// ---------------------------------------------------------------------
// Render quality
// ---------------------------------------------------------------------
$fn = 48;                        // facet count for cylinders / holes

// ---------------------------------------------------------------------
// Arm bracket interface                                  *** MEASURE ME ***
// ---------------------------------------------------------------------
// Centre-to-centre spacing of the two screw holes on the arm's metal
// bracket. VERIFIED 2026-07-17 with bracket_test_plate.scad — the 18 mm
// row fits the bracket holes cleanly.
bracket_hole_spacing_mm = 18;    // test-plate verified
bracket_screw_hole_d    = 3.4;   // M3 clearance (bracket holes confirmed M3)
                                 // (4.5 = M4 free fit; use 3.4 for M3, 5.5 for M5)
bracket_tab_w           = 12;    // width of each mounting ear
bracket_tab_l           = 10;    // how far each ear extends from the tray wall
bracket_tab_t           = 4;     // ear thickness (thicker than the floor: carries screw load)
bracket_hole_end_inset  = 5;     // hole centre, measured back from the ear's rounded tip

// Bracket plate thickness (measured 2 mm) — informs screw length choice:
// M3 x 8 reaches through ear (4) + bracket (2) with thread to spare.
bracket_plate_t         = 2;

// ---------------------------------------------------------------------
// Printed-part construction
// ---------------------------------------------------------------------
wall_t        = 2.4;   // vertical wall thickness (= 3 perimeters with a 0.4 mm nozzle)
floor_t       = 2.0;   // tray floor thickness
corner_r      = 3;     // outer corner radius of the trays
fit_clearance = 0.25;  // per-side gap between PCB edge and cavity wall (FDM slop)

// ---------------------------------------------------------------------
// Screws — machine screws thread-forming directly into printed pilot holes
// ---------------------------------------------------------------------
m3_free_d     = 3.4;   // M3 clearance hole
m3_pilot_d    = 2.7;   // M3 thread-forming pilot in PLA/PETG
m25_free_d    = 2.9;   // M2.5 clearance hole
m25_pilot_d   = 2.15;  // M2.5 thread-forming pilot in PLA/PETG
boss_wall_min = 1.8;   // minimum plastic wall around any pilot hole
pilot_depth   = 6;     // usable thread depth in a standoff boss

// ---------------------------------------------------------------------
// Ventilation slots
// ---------------------------------------------------------------------
vent_slot_w     = 3;   // slot width (stadium shape — self-supporting, no bridging issues)
vent_slot_pitch = 16;  // centre-to-centre spacing of slots within a row
vent_row_pitch  = 6.3; // centre-to-centre spacing between rows of slots

// =====================================================================
// Helper modules
// =====================================================================

// Rounded-corner rectangular plate. Footprint size_x by size_y, height h,
// corner radius r. Origin at the plate's minimum-x / minimum-y corner.
module rounded_plate(size_x, size_y, h, r = corner_r) {
    hull()
        for (px = [r, size_x - r], py = [r, size_y - r])
            translate([px, py, 0])
                cylinder(h = h, r = r);
}

// Stadium-shaped slot cutter. Length l along X, width w, punches through
// a floor/wall of thickness t (extends 0.1 past each face). Centred on
// the origin in X/Y; cuts z = -0.1 .. t + 0.1.
module vent_slot(l, w = vent_slot_w, t = floor_t) {
    translate([0, 0, -0.1])
        hull()
            for (px = [-(l - w) / 2, (l - w) / 2])
                translate([px, 0, 0])
                    cylinder(h = t + 0.2, d = w);
}

// PCB standoff boss: cylinder of height h with a screw pilot hole bored
// from the top. Sits on the origin; caller translates onto the floor.
module standoff(h, pilot_d, od = undef) {
    d = is_undef(od) ? pilot_d + 2 * boss_wall_min : od;
    difference() {
        cylinder(h = h, d = d);
        translate([0, 0, h - pilot_depth])
            cylinder(h = pilot_depth + 0.1, d = pilot_d);
    }
}

// Two mounting ears that screw onto the arm's metal bracket.
// Local frame: ears grow in +Y from y = 0 (place y = 0 just inside the
// tray's outer wall so the roots fuse to it), holes are spaced
// `spacing` apart along X and centred on x = 0, ears sit on z = 0.
// slot_len > 0 elongates each screw hole into a stadium slot along X
// (total extra travel; e.g. 4 = ±2 mm). Use on ONE pair of a two-pair
// mount: the round-hole pair is the fixed datum, the slotted pair
// floats to absorb frame seam movement / measurement slack.
module bracket_ears(spacing = bracket_hole_spacing_mm, slot_len = 0) {
    for (sx = [-1, 1])
        translate([sx * spacing / 2, 0, 0])
            difference() {
                hull() {
                    // root — extends 1 mm in -Y to fuse with the tray wall
                    translate([-bracket_tab_w / 2, -1, 0])
                        cube([bracket_tab_w, 1.1, bracket_tab_t]);
                    // rounded tip
                    translate([0, bracket_tab_l - bracket_tab_w / 2, 0])
                        cylinder(h = bracket_tab_t, d = bracket_tab_w);
                }
                // bracket screw hole (round, or slotted along X)
                translate([0, bracket_tab_l - bracket_hole_end_inset, -0.1])
                    hull()
                        for (ox = [-slot_len / 2, slot_len / 2])
                            translate([ox, 0, 0])
                                cylinder(h = bracket_tab_t + 0.2,
                                         d = bracket_screw_hole_d);
            }
}
