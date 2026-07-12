// =====================================================================
// pca9685_mount.scad
// Mounting tray for a standard PCA9685 16-channel 12-bit PWM servo
// driver board (Adafruit #815 form factor and its clones) — 6DOF robot
// arm project.
//
// Board facts (verified against the Adafruit design; measure clones):
// - PCB 62.5 x 25.4 mm, four 2.5-2.6 mm mounting holes on a
//   56 x 19 mm grid. M2.5 screws thread into printed standoff pilots.
// - Servo output headers (channels 0-15) along one long edge (-Y here):
//   fully open from the top; the front wall is dropped to PCB level so
//   servo plugs and fingers have room.
// - V+ / GND screw terminal block at the centre of the board: wires exit
//   over the +Y edge through a notch in the back wall.
// - I2C headers on both short ends: notches in both short walls.
// - Walls are deliberately low (wall_h_above_pcb over the PCB) so the
//   whole top stays accessible; the notches keep wiring tidy even if you
//   raise the walls.
//
// Bracket interface: two ears on the +Y long wall; hole spacing is
// bracket_hole_spacing_mm in common_params.scad (MEASURE ME).
// Assembly order: screw the tray to the arm bracket FIRST, then screw
// the PCB onto the standoffs (the bracket screws sit outside the PCB
// footprint, but tray-first is easier).
// Print flat as oriented — no supports needed.
// =====================================================================

include <common_params.scad>

// ---------------------------------------------------------------------
// PCA9685 board dimensions (verify your clone against these)
// ---------------------------------------------------------------------
pca_pcb_l          = 62.5;  // PCB length
pca_pcb_w          = 25.4;  // PCB width
pca_pcb_t          = 1.6;   // PCB thickness
pca_hole_spacing_l = 56.0;  // mounting hole spacing along the length
pca_hole_spacing_w = 19.0;  // mounting hole spacing along the width
pca_hole_d         = 2.6;   // board hole diameter -> M2.5 screws
pca_underside_max  = 3.0;   // tallest solder tails under the board

// ---------------------------------------------------------------------
// Tray geometry
// ---------------------------------------------------------------------
pca_standoff_h   = 6.0;   // standoff height (> pca_underside_max, adds airflow)
wall_h_above_pcb = 2.0;   // walls rise this far past the PCB top face

vplus_notch_w  = 14.0;    // back-wall notch for the V+/GND power wires
i2c_notch_w    = 17.0;    // short-wall notches for the 6-pin I2C headers
servo_cut_l    = pca_pcb_l - 12; // front wall dropped to PCB level over this length

// ---------------------------------------------------------------------
// Ventilation
// ---------------------------------------------------------------------
floor_vent_l  = 10.0;                        // floor slot length
floor_vent_xs = [-vent_slot_pitch, 0, vent_slot_pitch]; // slot columns
floor_vent_ys = [-vent_row_pitch, 0, vent_row_pitch];   // slot rows

// ---------------------------------------------------------------------
// Derived dimensions (do not edit)
// ---------------------------------------------------------------------
in_l       = pca_pcb_l + 2 * fit_clearance;  // cavity length
in_w       = pca_pcb_w + 2 * fit_clearance;  // cavity width
out_l      = in_l + 2 * wall_t;              // outer length
out_w      = in_w + 2 * wall_t;              // outer width
pcb_z      = floor_t + pca_standoff_h;       // PCB underside height
pcb_top_z  = pcb_z + pca_pcb_t;              // PCB top face height
wall_top_z = pcb_top_z + wall_h_above_pcb;   // total tray height

// =====================================================================
// Sub-modules
// =====================================================================

// Notch cutters: boxes that drop a wall section down to PCB-top level.
// w = notch width; callers translate them onto the wall being cut.
module wall_notch_x(w) {
    // through a short wall: box spanning the wall thickness in X
    translate([-0.1, -w / 2, pcb_top_z])
        cube([wall_t + 0.2, w, wall_top_z]);
}

module wall_notch_y(w) {
    // through a long wall: box spanning the wall thickness in Y
    translate([-w / 2, -0.1, pcb_top_z])
        cube([w, wall_t + 0.2, wall_top_z]);
}

// =====================================================================
// Main part
// =====================================================================
module pca9685_tray() {
    // ---- shell: outer walls + floor + bracket ears, minus openings ----
    difference() {
        union() {
            translate([-out_l / 2, -out_w / 2, 0])
                rounded_plate(out_l, out_w, wall_top_z);
            // bracket ears on the +Y long wall (away from the servo headers)
            translate([0, out_w / 2, 0])
                bracket_ears();
        }

        // interior cavity
        translate([-in_l / 2, -in_w / 2, floor_t])
            rounded_plate(in_l, in_w, wall_top_z - floor_t + 0.1,
                          r = max(corner_r - wall_t / 2, 1));

        // servo-header access: drop the -Y (front) wall to PCB level
        translate([0, -(in_w / 2 + wall_t), 0])
            wall_notch_y(servo_cut_l);

        // V+/GND power-wire notch, centre of the +Y (back) wall
        translate([0, in_w / 2, 0])
            wall_notch_y(vplus_notch_w);

        // I2C header notches, both short walls
        translate([in_l / 2, 0, 0])
            wall_notch_x(i2c_notch_w);
        translate([-(in_l / 2 + wall_t), 0, 0])
            wall_notch_x(i2c_notch_w);

        // floor ventilation slots
        for (vx = floor_vent_xs, vy = floor_vent_ys)
            translate([vx, vy, 0])
                vent_slot(floor_vent_l);
    }

    // ---- M2.5 standoffs on the 56 x 19 mm hole grid ----
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * pca_hole_spacing_l / 2,
                   sy * pca_hole_spacing_w / 2, floor_t])
            standoff(pca_standoff_h, m25_pilot_d);
}

pca9685_tray();
