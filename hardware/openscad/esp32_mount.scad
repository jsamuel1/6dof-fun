// =====================================================================
// esp32_mount.scad
// Open-top mounting tray for an Elegoo ESP32 development board
// (ESP-WROOM-32, 38-pin, USB-C) — 6DOF robot arm project.
//
// Design notes
// - Most Elegoo / DevKitC-style ESP32 boards have NO mounting holes, so
//   the default retention is mechanical: the board slides in tilted,
//   USB end first, under two fixed lips beside the USB-C slot, then the
//   antenna end presses down past two flexible snap posts. To release,
//   push the posts outward through the openings in the antenna-end wall.
// - If your board revision DOES have mounting holes, set
//   esp32_has_mounting_holes = true and measure the spacing; M3 screw
//   bosses are generated instead of relying on the snap posts alone.
// - The 38-pin header pins point DOWN (breadboard style) and protrude
//   well below the PCB; the board rides on central rails and end ledges
//   tall enough that the pins hang in free air above the floor.
// - USB-C port: open slot in one short wall. Pins, buttons (EN/BOOT)
//   and the antenna are reachable from the open top.
//
// Bracket interface: two ears on the +Y long wall; hole spacing is
// bracket_hole_spacing_mm in common_params.scad (MEASURE ME).
// Print flat as oriented — no supports needed.
// =====================================================================

include <common_params.scad>

// ---------------------------------------------------------------------
// ESP32 board dimensions                                *** MEASURE ME ***
// (defaults are typical for the Elegoo ESP-WROOM-32 USB-C 38-pin board;
//  verify with calipers — clone dimensions vary by a millimetre or two)
// ---------------------------------------------------------------------
esp32_pcb_l          = 52.0;  // MEASURE ME: PCB length, USB edge to antenna edge
esp32_pcb_w          = 28.9;  // MEASURE ME: PCB width across the two pin rows
esp32_pcb_t          = 1.7;   // PCB thickness (1.6 nominal + solder mask)
esp32_pin_protrusion = 9.0;   // MEASURE ME: header pins + plastic below the PCB underside
esp32_pin_row_depth  = 5.0;   // how far the pin rows reach inboard from each long edge
esp32_module_w       = 18.0;  // WROOM-32 module width (keep clips clear of the antenna end)

// Optional screw mounting (rare on these boards — measure before enabling)
esp32_has_mounting_holes = false; // set true only if YOUR board has holes
esp32_hole_spacing_l     = 44.0;  // MEASURE ME (only used when holes enabled)
esp32_hole_spacing_w     = 23.0;  // MEASURE ME (only used when holes enabled)

// ---------------------------------------------------------------------
// Tray geometry
// ---------------------------------------------------------------------
pin_floor_clearance = 2.0;    // air gap between pin tips and the tray floor
standoff_h          = esp32_pin_protrusion + pin_floor_clearance; // PCB underside height above floor
wall_h_above_pcb    = 3.0;    // side walls rise this far past the PCB top face

usb_cut_w         = 13.0;     // USB-C access slot width (plug overmolds run ~12 mm)
usb_cut_below_pcb = 1.0;      // slot starts this far below the PCB underside

rail_w        = 4.0;          // width of each central support rail
rail_offset_y = 5.0;          // rail centreline offset from the board centreline
                              // (keeps rails inboard of the downward pin rows)
ledge_d       = 4.0;          // depth (along X) of the support ledge under each short edge
ledge_w       = 10.0;         // width (along Y) of each end ledge

// ---------------------------------------------------------------------
// Board retention: fixed lips (USB end) + flexible snap posts (antenna end)
// ---------------------------------------------------------------------
clip_w          = 4.0;   // snap post width
clip_t          = 2.0;   // snap post thickness (thin enough to flex; PETG recommended)
clip_lip        = 1.0;   // how far the snap lip overhangs the PCB top face
clip_gap        = 0.15;  // vertical slack between PCB top and the lip underside
clip_slit       = 1.5;   // free gap beside each snap post (lets it flex)
clip_module_gap = 0.5;   // lateral clearance between clip and the WROOM module edge

usb_lip_w        = 4.0;  // width of each fixed lip beside the USB slot
usb_lip_overhang = 1.2;  // fixed lip overhang over the PCB top face
usb_lip_h        = 2.0;  // fixed lip height (sloped top for easy tilted insertion)

// ---------------------------------------------------------------------
// Ventilation
// ---------------------------------------------------------------------
floor_vent_l  = 10.0;                       // floor slot length
floor_vent_xs = [-vent_slot_pitch, 0, vent_slot_pitch]; // slot columns
floor_vent_ys = [-10.5, 0, 10.5];           // slot rows (clear of rails and ledges)
wall_vent_l   = 14.0;                       // long-wall slot length
wall_vent_w   = 3.5;                        // long-wall slot width
wall_vent_xs  = [-13, 13];                  // long-wall slot positions
wall_vent_z   = floor_t + 5;                // long-wall slot centre height

// ---------------------------------------------------------------------
// Derived dimensions (do not edit)
// ---------------------------------------------------------------------
in_l          = esp32_pcb_l + 2 * fit_clearance;  // cavity length
in_w          = esp32_pcb_w + 2 * fit_clearance;  // cavity width
out_l         = in_l + 2 * wall_t;                // outer length
out_w         = in_w + 2 * wall_t;                // outer width
pcb_z         = floor_t + standoff_h;             // PCB underside height
pcb_top_z     = pcb_z + esp32_pcb_t;              // PCB top face height
wall_top_z    = pcb_top_z + wall_h_above_pcb;     // total tray height
clip_offset_y = esp32_module_w / 2 + clip_w / 2 + clip_module_gap; // snap post Y positions
usb_lip_off_y = usb_cut_w / 2 + usb_lip_w / 2 + 1;                 // fixed lip Y positions
rail_l        = esp32_pcb_l - 2 * ledge_d - 4;    // rail length (stops short of end ledges)

// =====================================================================
// Sub-modules
// =====================================================================

// Flexible snap post inside the -X (antenna-end) wall pocket.
// Cantilevered from the floor; the lip has 45-degree ramps top and
// bottom so the board snaps in from above and can be pried out.
module snap_post(yc) {
    x0 = -in_l / 2;                       // cavity inner face at the -X wall
    z0 = pcb_top_z + clip_gap;            // lip underside height
    // post body
    translate([x0 - clip_t, yc - clip_w / 2, floor_t])
        cube([clip_t, clip_w, (z0 + 2 * clip_lip) - floor_t]);
    // lip (triangular prism protruding inward, +X; the -0.1 back face
    // embeds it into the post so the union is watertight)
    translate([x0, yc + clip_w / 2, 0])
        rotate([90, 0, 0])
            linear_extrude(height = clip_w)
                polygon([[-0.1, z0],
                         [clip_lip, z0 + clip_lip],
                         [-0.1, z0 + 2 * clip_lip]]);
}

// Pocket cut through the -X wall around a snap post so it can flex.
module snap_pocket(yc) {
    translate([-out_l / 2 - 0.1, yc - (clip_w / 2 + clip_slit), floor_t])
        cube([wall_t + 0.2, clip_w + 2 * clip_slit, wall_top_z]);
}

// Fixed retention lip on the +X (USB-end) wall: flat underside holds the
// board down, sloped top guides the tilted board underneath it.
module usb_lip(yc) {
    x1 = in_l / 2;                        // cavity inner face at the +X wall
    z0 = pcb_top_z + clip_gap;            // lip underside height
    // (the +0.5 back edge embeds the lip into the wall for a clean union)
    translate([x1, yc + usb_lip_w / 2, 0])
        rotate([90, 0, 0])
            linear_extrude(height = usb_lip_w)
                polygon([[0.5, z0],
                         [-usb_lip_overhang, z0],
                         [0.5, z0 + usb_lip_h]]);
}

// Horizontal vent slot through a long wall (call for +Y; mirror for -Y).
module wall_vent(cx) {
    translate([cx, in_w / 2 + wall_t + 0.2, wall_vent_z])
        rotate([90, 0, 0])
            vent_slot(wall_vent_l, wall_vent_w, wall_t + 0.4);
}

// =====================================================================
// Main part
// =====================================================================
module esp32_tray() {
    // ---- shell: outer walls + floor + bracket ears, minus openings ----
    difference() {
        union() {
            translate([-out_l / 2, -out_w / 2, 0])
                rounded_plate(out_l, out_w, wall_top_z);
            // bracket ears on the +Y long wall
            translate([0, out_w / 2, 0])
                bracket_ears();
        }

        // interior cavity
        translate([-in_l / 2, -in_w / 2, floor_t])
            rounded_plate(in_l, in_w, wall_top_z - floor_t + 0.1,
                          r = max(corner_r - wall_t / 2, 1));

        // USB-C access slot in the +X short wall (open to the top edge)
        translate([in_l / 2 - 0.1, -usb_cut_w / 2, pcb_z - usb_cut_below_pcb])
            cube([wall_t + 0.3, usb_cut_w, wall_top_z]);

        // floor ventilation slots
        for (vx = floor_vent_xs, vy = floor_vent_ys)
            translate([vx, vy, 0])
                vent_slot(floor_vent_l);

        // long-wall ventilation slots (both sides)
        for (vx = wall_vent_xs) {
            wall_vent(vx);
            mirror([0, 1, 0]) wall_vent(vx);
        }

        // flex pockets around the snap posts (-X wall)
        for (sy = [-1, 1])
            snap_pocket(sy * clip_offset_y);
    }

    // ---- interior features (added after the difference so the vent /
    //      pocket cuts never truncate them) ----

    // central support rails (between the downward pin rows)
    for (sy = [-1, 1])
        translate([-rail_l / 2, sy * rail_offset_y - rail_w / 2, floor_t])
            cube([rail_l, rail_w, standoff_h]);

    // support ledges under each short edge of the PCB
    for (sx = [-1, 1])
        translate([sx * (in_l / 2 - ledge_d / 2) - ledge_d / 2,
                   -ledge_w / 2, floor_t])
            cube([ledge_d, ledge_w, standoff_h]);

    // flexible snap posts (antenna end)
    for (sy = [-1, 1])
        snap_post(sy * clip_offset_y);

    // fixed lips beside the USB slot (USB end)
    for (sy = [-1, 1])
        usb_lip(sy * usb_lip_off_y);

    // optional M3 screw bosses (only if your board has mounting holes)
    if (esp32_has_mounting_holes)
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * esp32_hole_spacing_l / 2,
                       sy * esp32_hole_spacing_w / 2, floor_t])
                standoff(standoff_h, m3_pilot_d);
}

esp32_tray();
