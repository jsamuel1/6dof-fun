// =====================================================================
// electronics_spine.scad — one linear enclosure for BOTH boards,
// mounted head-to-tail along the arm. Power enters at the bottom
// (arm-base) end; servo leads exit sideways along the PCA9685 bay.
//
//   arm base (power in)                                    up-arm ->
//   +--------------------------------------------------------------+
//   | entry | PCA9685 bay (V+ wire straight in,  | ESP32 bay       |
//   | wall  | servo slots along both sides)      | (USB-C faces    |
//   |  ##   |                                    |  the divider;   |
//   |  ##   |                                    |  antenna up-arm)|
//   +--------------------------------------------------------------+
//        ^ entry wall: XT60 panel-mount 6V inlet -> PCA9685 terminal,
//          USB-C cable port -> floor channel beside the PCA9685 bay
//
// Layout rationale:
//   * PCA9685 nearest the power entry: the soldered V+ feed stays short.
//   * ESP32 antenna points up-arm, away from the metal bracket mass.
//   * USB-C faces the PCA9685 bay; its cable travels a side channel back
//     to the entry wall, so both external cables leave at the same end.
//   * Bracket ears (18 mm M3 pattern, common_params) on the back wall,
//     one pair per bay. VERIFY spacing with the test plate first!
//
// Parts (-D 'part="..."'): "body" | "lid" | "both"
// Print flat, no supports; PLA fit check, then PETG.
// =====================================================================

include <common_params.scad>

part = "body";

// --- boards (from esp32_mount.scad / pca9685_mount.scad) -------------
esp32_pcb_l = 52.0;   esp32_pcb_w = 28.9;   esp32_pin_h = 9.0;
pca_pcb_l   = 62.5;   pca_pcb_w   = 25.4;
pca_hole_dl = 56.0;   pca_hole_dw = 19.0;   pca_hole_off_l = (pca_pcb_l - 56.0) / 2;

// --- layout ----------------------------------------------------------
bay_gap     = 18;     // divider + USB-C plug bay (plug ~12 mm + finger room)
entry_wall  = 6;      // thick bottom wall carrying the two cable ports
usb_chan_w  = 9;      // floor channel beside the PCA9685 bay for USB run
inner_w     = max(esp32_pcb_w, pca_pcb_w) + 2 * fit_clearance;  // 29.4
box_inner_l = entry_wall + pca_pcb_l + bay_gap + esp32_pcb_l + 4;
box_l = box_inner_l + wall_t;
box_w = inner_w + usb_chan_w + 3 * wall_t;
// Height is governed by the PCA9685's servo plugs standing on their
// vertical headers: board top 7.6 + pin/plug stack ~14 = ~21.6, plus
// wire-bend room. 22 inner is the honest minimum with straight plugs.
box_h = floor_t + 22;

pca_x   = entry_wall;                        // PCA9685 bay start
esp_x   = entry_wall + pca_pcb_l + bay_gap;  // ESP32 bay start
bay_y   = 2 * wall_t + usb_chan_w;           // bays sit past the USB channel

// --- 6V power inlet (entry wall, PCA bay) ---------------------------
// Defaults fit an XT60E-M flag-style panel mount. For a different
// connector, adjust the nose cutout / flange pocket / screw spacing.
pwr_cut_w   = 15.8;   // nose cutout width  (across the wall, y)
pwr_cut_h   = 8.4;    // nose cutout height (z)
pwr_pock_w  = 28.5;   // flange pocket on the outer face
pwr_pock_h  = 14.5;
pwr_panel_t = 2.0;    // panel thickness left for the flange
pwr_screw_p = 20.6;   // flange screw spacing
pwr_screw_d = 2.05;   // thread-forming pilot for the flange screws
pwr_z       = 10;     // connector centre height

// --- arm-face hardware relief (underside) ---------------------------
// The arm's own assembly screws stand proud of its mounting face, right
// at the centre of each 18 mm hole pair (the servo bolt-circle).
//   datum end (entry pair):   screw heads / washer -> shallow circular
//     recess in a locally thickened floor pad; the spine still bears on
//     the arm face around it.
//   floating end (slotted pair): screw tip + nut -> elongated
//     through-slot, so the taller stack passes into the bay and can
//     travel with the frame-seam movement (matches the +-2 mm mount
//     slots). Nut clears under the ESP32, which rides 9 mm up on rails.
// Confirm on the PLA fit check; adjust these if a protrusion differs.
head_recess_d     = 18;    // covers centre screw + washer + bolt-circle heads
head_recess_depth = 3.0;   // proudest head ~2.5 -> 0.5 air
head_pad_d        = 24;    // interior pad giving the recess its depth
nut_slot_w        = 9;     // M3 nut (6.9 a/c) + clearance
nut_slot_l        = 13;    // width + 4 mm travel (mount-slot match);
                           // tips just kiss the mount slots — harmless,
                           // the washered mount screws bridge the notch
// NOTE: use washers under the two datum M3 heads inside — the recess
// lobe clips the hole edge, so the washer spreads load onto the pad.

module spine_body() {
  difference() {
    union() {
    difference() {
        rounded_plate(box_l, box_w, box_h);
        // hollow: main cavity (both bays + divider gap)
        translate([pca_x, bay_y, floor_t])
            cube([box_inner_l - entry_wall, inner_w, box_h]);
        // hollow: USB cable channel from entry to the ESP32 bay mouth
        translate([pca_x, wall_t, floor_t])
            cube([esp_x - entry_wall + 6, usb_chan_w, box_h]);
        // divider stays: re-add below. Entry-wall cable ports:
        // 6V power inlet — panel-mount connector on the PCA bay's entry
        // edge (sized for an XT60E-M flag mount; edit the pwr_* params
        // for another connector). The outer face is pocketed down to a
        // 2 mm panel; the nose pokes through the cutout and the flange
        // screws to the panel from outside.
        translate([-0.1, bay_y + inner_w / 2 - pwr_cut_w / 2,
                   pwr_z - pwr_cut_h / 2])
            cube([entry_wall + 0.2, pwr_cut_w, pwr_cut_h]);
        translate([-0.1, bay_y + inner_w / 2 - pwr_pock_w / 2,
                   pwr_z - pwr_pock_h / 2])
            cube([entry_wall - pwr_panel_t + 0.1, pwr_pock_w, pwr_pock_h]);
        for (sy = [-1, 1])
            translate([-0.1, bay_y + inner_w / 2 + sy * pwr_screw_p / 2, pwr_z])
                rotate([0, 90, 0])
                    cylinder(h = entry_wall + 0.2, d = pwr_screw_d);
        // USB-C cable port (into the channel)
        translate([-0.1, wall_t + usb_chan_w / 2 - 4.5, floor_t])
            cube([entry_wall + 0.2, 9, box_h]);
        // servo lead slots: FRONT wall (away from the bracket/arm side),
        // 3 slots of 2 channels each along the PCA9685 bay. Open to the
        // rim — wires drop in from above, the lid closes the top.
        for (i = [0 : 2])
            translate([pca_x + 6 + i * 18, -0.1, floor_t + 3])
                cube([13, wall_t + 0.2, box_h]);
        // punch-hole ventilation, both long walls + ESP32 bay far side
        for (zr = [0 : 2], xi = [0 : floor((box_l - 16) / punch_pitch_spine)]) {
            x = 8 + xi * punch_pitch_spine + (zr % 2) * punch_pitch_spine / 2;
            z = box_h - 14 + zr * 4;
            for (y = [-0.1, box_w - wall_t - 0.1])
                translate([x, y, z]) rotate([-90, 0, 0])
                    cylinder(h = wall_t + 0.2, d = 2.2);
        }
        // antenna end: generous opening (WiFi + USB-brick heat)
        translate([box_l - wall_t - 0.1, bay_y + 4, floor_t + 4])
            cube([wall_t + 0.2, inner_w - 8, box_h]);

        // inner raceway wall: punched through for weight and cross-flow
        // (air path: outer wall punches -> bay -> raceway -> outer wall)
        for (zr = [0, 1], xi = [0 : 10])
            translate([10 + xi * 5.2 + zr * 2.6,
                       wall_t + usb_chan_w - 0.1, 8 + zr * 5])
                rotate([-90, 0, 0])
                    cylinder(h = wall_t + 0.2, d = 2.2);

        // raceway mouth: open the channel wall across the USB plug bay so
        // the cable turns 90 deg from the plug into the raceway. Open to
        // the rim (the divider carries the structure there).
        translate([esp_x - bay_gap + wall_t + 3, wall_t + usb_chan_w - 0.1, floor_t])
            cube([bay_gap - wall_t - 5, 2 * wall_t + 0.2 - 2.2, box_h]);

        // USB access opening: front wall, directly in line with the plug
        // bay and raceway mouth — a straight finger/cable tunnel from
        // outside to the USB-C port. Open to the rim, lid closes the top.
        translate([esp_x - bay_gap + wall_t + 3, -0.1, floor_t + 2])
            cube([bay_gap - wall_t - 5, wall_t + 0.2, box_h]);
    }
    // divider wall on the PCA side of the gap — the gap itself is the
    // USB-C plug bay (plug seats into the ESP32 across it)
    difference() {
        translate([pca_x + pca_pcb_l + 1, bay_y, floor_t])
            cube([wall_t + 2, inner_w, box_h - floor_t - 6]);
        translate([pca_x + pca_pcb_l + 0.9, bay_y + inner_w / 2 - 8, box_h - 14])
            cube([wall_t + 2.2, 16, 20]);
    }
    // interior pad under the PCA9685: gives the head recess its depth.
    // 2.4 tall — stays 1.6 under the board (standoffs are 4).
    translate([ear_group_center - ear_pair_pitch / 2, box_w / 2, 0])
        cylinder(h = head_recess_depth + 1.4, d = head_pad_d);
    // PCA9685 corner standoffs (M2.5) — hole pattern centred in the bay
    // (entry wall to divider face along x, full inner width along y)
    for (px = [-1, 1], py = [-1, 1])
        translate([pca_x + (pca_pcb_l + 1) / 2 + px * pca_hole_dl / 2,
                   bay_y + inner_w / 2 + py * pca_hole_dw / 2,
                   floor_t])
            standoff(4, m25_pilot_d);
    // ESP32 support rails (pins hang between them, breadboard-style).
    // Inset 4.5 from the bay walls so the pin-header bases clear the
    // plastic, and tapered to a 2 mm top so the board drops on without
    // a fight (v1 at 3 mm inset needed a shove).
    for (y = [bay_y + 4.5, bay_y + inner_w - 4.5 - rail_w_spine])
        translate([esp_x, y, floor_t])
            hull() {
                cube([esp32_pcb_l - 4, rail_w_spine, 0.1]);
                translate([0, rail_w_spine / 2 - 1, esp32_pin_h - 0.1])
                    cube([esp32_pcb_l - 4, 2, 0.1]);
            }
    }   // end union

    // ---- cuts through EVERYTHING (floor + pad + rails) ----------------
    // CENTRE-LINE mounting: M3 holes through the floor matched to the
    // arm's *<-18->*<-32->*<-18->* row, so the spine sits ON the arm
    // instead of cantilevering off an edge ear. Entry-end pair round
    // (datum, pierces the head-relief pad — use washers inside);
    // up-arm pair slotted ±2 mm for the seam.
    for (dx = [-ear_pair_pitch / 2 - 9, -ear_pair_pitch / 2 + 9])
        translate([ear_group_center + dx, box_w / 2, -0.1])
            cylinder(h = box_h + 0.2, d = m3_free_d);
    for (dx = [ear_pair_pitch / 2 - 9, ear_pair_pitch / 2 + 9])
        translate([ear_group_center + dx, box_w / 2, -0.1])
            hull()
                for (ox = [-2, 2])
                    translate([ox, 0, 0])
                        cylinder(h = floor_t + 0.2, d = m3_free_d);
    // head recess: underside circular pocket at the datum pair centre
    translate([ear_group_center - ear_pair_pitch / 2, box_w / 2, -0.1])
        cylinder(h = head_recess_depth + 0.1, d = head_recess_d);
    // nut slot: elongated through-cut at the slotted pair centre; the
    // screw tip + nut ride up between the ESP32 rails, under the board
    translate([ear_group_center + ear_pair_pitch / 2, box_w / 2, -0.1])
        hull()
            for (ox = [-(nut_slot_l - nut_slot_w) / 2,
                        (nut_slot_l - nut_slot_w) / 2])
                translate([ox, 0, 0])
                    cylinder(h = floor_t + 0.2, d = nut_slot_w);
  }
}

punch_pitch_spine = 5;
rail_w_spine = 4;
// Arm hole row (verified): pair-to-pair centre distance = 18/2 + 32 + 18/2.
ear_pair_pitch   = 50;
ear_group_center = box_l / 2;   // ear group centred on the spine

// The shared motif at a finer pitch to suit the narrow lid; the '#'
// cells become the second-colour body (part="art"), the field around
// them is uniform fine punch holes on the same grid.
include <art_motif.scad>
art_pitch_s  = 2.2;
art_hole_s   = 1.5;
lid_margin_s = 5;
art_w_s = art_motif_cols * art_pitch_s;   // 52.8 along the spine
art_h_s = art_motif_rows * art_pitch_s;   // 35.2 across it
art_x0  = (box_l - art_w_s) / 2;
art_y0  = (box_w - art_h_s) / 2;

// true where grid cell (ix, iy) — indexed from the art block origin —
// lands on a solid '#' motif cell
function motif_solid(ix, iy) =
    ix >= 0 && ix < art_motif_cols && iy >= 0 && iy < art_motif_rows &&
    art_motif[art_motif_rows - 1 - iy][ix] != ".";

module spine_art_body(sym = "*") {
    for (iy = [0 : art_motif_rows - 1], ix = [0 : art_motif_cols - 1])
        if (motif_solid(ix, iy) &&
            (sym == "*" ||
             art_motif[art_motif_rows - 1 - iy][ix] == sym))
            translate([art_x0 + ix * art_pitch_s - 0.005,
                       art_y0 + iy * art_pitch_s - 0.005, 0])
                cube([art_pitch_s + 0.01, art_pitch_s + 0.01, lid_t_spine]);
}

module spine_lid() {
    ix_lo = -ceil((art_x0 - lid_margin_s) / art_pitch_s);
    ix_hi = art_motif_cols - 1 + ceil((box_l - art_x0 - art_w_s - lid_margin_s) / art_pitch_s);
    iy_lo = -ceil((art_y0 - lid_margin_s) / art_pitch_s);
    iy_hi = art_motif_rows - 1 + ceil((box_w - art_y0 - art_h_s - lid_margin_s) / art_pitch_s);
    difference() {
        union() {
            rounded_plate(box_l, box_w, lid_t_spine);
            // skirt walls drop just inside the box rim
            difference() {
                translate([wall_t + fit_clearance, wall_t + fit_clearance, -5])
                    rounded_plate(box_l - 2 * (wall_t + fit_clearance),
                                  box_w - 2 * (wall_t + fit_clearance), 5,
                                  corner_r - 1);
                translate([wall_t + fit_clearance + 1.6,
                           wall_t + fit_clearance + 1.6, -5.1])
                    rounded_plate(box_l - 2 * (wall_t + fit_clearance + 1.6),
                                  box_w - 2 * (wall_t + fit_clearance + 1.6),
                                  5.2, corner_r - 1);
            }
        }
        // through-cut for the second-colour art body
        translate([0, 0, -0.1]) scale([1, 1, 1.2]) spine_art_body();
        // fine punch-hole field on the motif grid, skipping solid cells
        for (iy = [iy_lo : iy_hi], ix = [ix_lo : ix_hi]) {
            px = art_x0 + (ix + 0.5) * art_pitch_s;
            py = art_y0 + (iy + 0.5) * art_pitch_s;
            if (!motif_solid(ix, iy) &&
                px > lid_margin_s && px < box_l - lid_margin_s &&
                py > lid_margin_s && py < box_w - lid_margin_s)
                translate([px, py, -0.1])
                    cylinder(h = lid_t_spine + 0.2, d = art_hole_s);
        }
    }
}

lid_t_spine = 2.0;

// plate_dx/plate_dy: shift the emitted part on the print plate
// (used by the combined-project export; override with -D)
module spine_to_print() {
    translate([0, 2 * box_w + 15, lid_t_spine])
        rotate([180, 0, 0])
            translate([0, -box_w, 0])
                children();
}

plate_dx = 0;
plate_dy = 0;
translate([plate_dx, plate_dy, 0]) {
    if (part == "body") spine_body();
    if (part == "lid") spine_lid();
    if (part == "art_arm") spine_art_body("A");
    if (part == "art_berry") spine_art_body("B");
    // print-orientation plate variants (lid face-down, skirt up, art
    // coplanar) positioned beside the body for the Bambu project
    if (part == "lid_plate") spine_to_print() spine_lid();
    if (part == "art_arm_plate") spine_to_print() spine_art_body("A");
    if (part == "art_berry_plate") spine_to_print() spine_art_body("B");
    if (part == "both") {
        spine_body();
        translate([0, box_w + 12, 5]) spine_lid();
        translate([0, box_w + 12, 5]) color("white") spine_art_body("A");
    translate([0, box_w + 12, 5]) color("red") spine_art_body("B");
    }
}
