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
//        ^ two cable ports: 6V pair -> PCA9685, USB-C -> ESP32
//          (USB cable runs in a floor channel beside the PCA9685 bay)
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
bay_gap     = 8;      // divider wall + I2C ribbon pass-over
entry_wall  = 6;      // thick bottom wall carrying the two cable ports
usb_chan_w  = 9;      // floor channel beside the PCA9685 bay for USB run
inner_w     = max(esp32_pcb_w, pca_pcb_w) + 2 * fit_clearance;  // 29.4
box_inner_l = entry_wall + pca_pcb_l + bay_gap + esp32_pcb_l + 4;
box_l = box_inner_l + wall_t;
box_w = inner_w + usb_chan_w + 3 * wall_t;
box_h = floor_t + esp32_pin_h + 1.7 + 14;   // pins + pcb + wiring headroom

pca_x   = entry_wall;                        // PCA9685 bay start
esp_x   = entry_wall + pca_pcb_l + bay_gap;  // ESP32 bay start
bay_y   = 2 * wall_t + usb_chan_w;           // bays sit past the USB channel

module spine_body() {
    difference() {
        rounded_plate(box_l, box_w, box_h);
        // hollow: main cavity (both bays + divider gap)
        translate([pca_x, bay_y, floor_t])
            cube([box_inner_l - entry_wall, inner_w, box_h]);
        // hollow: USB cable channel from entry to the ESP32 bay mouth
        translate([pca_x, wall_t, floor_t])
            cube([esp_x - entry_wall + 6, usb_chan_w, box_h]);
        // divider stays: re-add below. Entry-wall cable ports:
        // 6V pair port (into PCA9685 bay, floor level)
        translate([-0.1, bay_y + inner_w / 2 - 5, floor_t])
            cube([entry_wall + 0.2, 10, 8]);
        // USB-C cable port (into the channel)
        translate([-0.1, wall_t + usb_chan_w / 2 - 4.5, floor_t])
            cube([entry_wall + 0.2, 9, 12]);
        // servo lead slots: FRONT wall (away from the bracket/arm side),
        // 3 slots of 2 channels each along the PCA9685 bay
        for (i = [0 : 2])
            translate([pca_x + 6 + i * 18, -0.1, floor_t + 3])
                cube([13, wall_t + 0.2, 12]);
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
    }
    // divider wall between bays, with an I2C ribbon notch on top
    difference() {
        translate([esp_x - wall_t - 2, bay_y, floor_t])
            cube([wall_t + 2, inner_w, box_h - floor_t - 6]);
        translate([esp_x - wall_t - 2.1, bay_y + inner_w / 2 - 8, box_h - 14])
            cube([wall_t + 2.2, 16, 20]);
        // USB-C mouth through the divider into the channel side
        translate([esp_x - wall_t - 2.1, bay_y - 0.1, floor_t + 2])
            cube([wall_t + 2.2, 2, 10]);
    }
    // PCA9685 corner standoffs (M2.5)
    for (px = [0, 1], py = [0, 1])
        translate([pca_x + pca_hole_off_l + fit_clearance + px * pca_hole_dl,
                   bay_y + (pca_pcb_w - pca_hole_dw) / 2 + py * pca_hole_dw,
                   floor_t])
            standoff(4, m25_pilot_d);
    // ESP32 support rails (pins hang between them, breadboard-style)
    for (y = [bay_y + 3, bay_y + inner_w - 3 - rail_w_spine])
        translate([esp_x, y, floor_t])
            cube([esp32_pcb_l - 4, rail_w_spine, esp32_pin_h]);
    // bracket ears: matched to the arm's real hole row (measured
    // 2026-07-17): four holes in a line, *<-18->*<-32->*<-18->*, i.e.
    // two 18 mm pairs with centres 50 mm apart, straddling the arm's
    // centre seam. Ear group is centred on the spine's length.
    // entry-end pair = fixed datum (round holes); up-arm pair slotted
    // ±2 mm along the spine so the seam-spanning 50 mm pitch can breathe
    translate([ear_group_center - ear_pair_pitch / 2, box_w - 0.1, 0])
        bracket_ears();
    translate([ear_group_center + ear_pair_pitch / 2, box_w - 0.1, 0])
        bracket_ears(slot_len = 4);
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
    art_motif[art_motif_rows - 1 - iy][ix] == "#";

module spine_art_body() {
    for (iy = [0 : art_motif_rows - 1], ix = [0 : art_motif_cols - 1])
        if (motif_solid(ix, iy))
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

if (part == "body") spine_body();
if (part == "lid") spine_lid();
if (part == "art") spine_art_body();
// print-orientation plate variants (lid face-down, skirt up, art
// coplanar) positioned beside the body for the Bambu project
module spine_to_print() {
    translate([0, 2 * box_w + 15, lid_t_spine])
        rotate([180, 0, 0])
            translate([0, -box_w, 0])
                children();
}
if (part == "lid_plate") spine_to_print() spine_lid();
if (part == "art_plate") spine_to_print() spine_art_body();
if (part == "both") {
    spine_body();
    translate([0, box_w + 12, 5]) spine_lid();
    translate([0, box_w + 12, 5]) color("red") spine_art_body();
}
