// =====================================================================
// pi4_mount.scad — open-frame tray for the Raspberry Pi 4B host.
//
// Same family as esp32_mount / pca9685_mount: ventilated floor, corner
// standoffs, optional arm-bracket ears. Open-frame (low rails, no lid)
// so all ports, the GPIO header, the SD slot, and airflow stay free —
// this Pi runs Docker 24/7 and prefers breathing over looking boxed.
//
// Print: PLA fit-check, then PETG · 4 perimeters · ~30% infill ·
// no supports (flat).
// =====================================================================

include <common_params.scad>

// --- Raspberry Pi 4B PCB (RPi mechanical drawing) --------------------
pi_pcb_l        = 85;    // long edge (USB/Ethernet at one short end)
pi_pcb_w        = 56;    // short edge
pi_hole_dx      = 58;    // mounting hole spacing, long axis
pi_hole_dy      = 49;    // mounting hole spacing, short axis
pi_hole_off     = 3.5;   // hole centre inset from PCB corner (both axes)
pi_standoff_h   = 6;     // clearance under PCB: SD card body + solder tails

// --- Tray ------------------------------------------------------------
rail_h          = 12;    // low side rails; all ports open above them
port_end_open   = true;  // USB/Ethernet short end: no rail at all
with_bracket_ears = false; // true -> arm-bracket ears (18 mm M3 pattern)

tray_l = pi_pcb_l + 2 * (wall_t + fit_clearance);
tray_w = pi_pcb_w + 2 * (wall_t + fit_clearance);

module pi4_tray() {
    difference() {
        union() {
            // floor
            rounded_plate(tray_l, tray_w, floor_t);
            // side rails: two long walls + SD short end (ports end open)
            for (y = [0, tray_w - wall_t])
                translate([0, y, 0])
                    cube([tray_l, wall_t, rail_h]);
            if (!port_end_open)
                cube([wall_t, tray_w, rail_h]);
            translate([tray_l - wall_t, 0, 0])
                cube([wall_t, tray_w, rail_h]);
            // corner standoffs, M2.5 thread-forming pilots
            for (px = [0, 1], py = [0, 1])
                translate([wall_t + fit_clearance + pi_hole_off + px * pi_hole_dx,
                           wall_t + fit_clearance + pi_hole_off + py * pi_hole_dy,
                           floor_t])
                    standoff(pi_standoff_h, m25_pilot_d);
            // ears (optional): screw the tray onto the arm's metal bracket
            if (with_bracket_ears)
                translate([tray_l / 2, tray_w - 0.1, 0])
                    bracket_ears();
        }
        // ventilation: slot grid under the SoC half of the board
        for (row = [0 : 4], col = [0 : 2])
            translate([tray_l * 0.22 + col * (vent_slot_pitch + 6),
                       tray_w * 0.28 + row * vent_row_pitch, 0])
                vent_slot(vent_slot_pitch, vent_slot_w, floor_t);
        // long-side relief: USB-C + 2x micro-HDMI sit low on the PCB;
        // drop that rail to floor level along the connector zone
        translate([wall_t + fit_clearance + 1.5, -0.1, floor_t])
            cube([50, wall_t + 0.2, rail_h]);
        // GPIO side relief for ribbon cables
        translate([tray_l - 54, tray_w - wall_t - 0.1, floor_t + 6])
            cube([50, wall_t + 0.2, rail_h]);
    }
}

pi4_tray();
