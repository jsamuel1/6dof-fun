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
esp_hole_dl = 46.5;   esp_hole_dw = 23.3;   // corner screw holes  *** MEASURE ME ***
pca_pcb_l   = 62.5;   pca_pcb_w   = 25.4;
pca_hole_dl = 56.0;   pca_hole_dw = 19.0;   pca_hole_off_l = (pca_pcb_l - 56.0) / 2;

// --- layout ----------------------------------------------------------
bay_gap     = 18;     // divider + USB-C plug bay (plug ~12 mm + finger room)
entry_wall  = 6;      // thick bottom wall carrying the two cable ports
usb_chan_w  = 9;      // floor channel beside the PCA9685 bay for USB run
pca_pin_clear = 7.5;  // the PCA9685's 6-pin end headers are RIGHT-ANGLE,
                      // pins pointing horizontally out past each board
                      // end (~6 mm at ~10 mm height) — the board sits
                      // this far off the entry wall so the unused
                      // entry-end pins float in free air
inner_w     = max(esp32_pcb_w, pca_pcb_w) + 2 * fit_clearance;  // 29.4
box_inner_l = entry_wall + pca_pin_clear + pca_pcb_l + bay_gap
              + esp32_pcb_l + 4;
box_l = box_inner_l + wall_t;
box_w = inner_w + usb_chan_w + 3 * wall_t;
// Height is governed by two stacks, both ~21.5:
//   * PCA9685 servo plugs on their vertical headers: board top 7.6 +
//     pin/plug stack ~14, plus wire-bend room.
//   * ESP32 pins-DOWN on 14.5 rails (Dupont housings below the
//     board): board top 18.1, USB-C plug tops out ~23 under the
//     24-high lid plane.
// 22 inner (lid underside at 24) covers both.
box_h = floor_t + 22;

pca_x   = entry_wall;                        // PCA9685 bay start (void)
pca_bx0 = pca_x + pca_pin_clear;             // PCA9685 board datum
esp_x   = entry_wall + pca_pin_clear + pca_pcb_l + bay_gap;  // ESP32 bay
bay_y   = 2 * wall_t + usb_chan_w;           // bays sit past the USB channel
esp_bay_y = box_w / 2 - inner_w / 2;         // ESP32 section CENTRED on the
                                             // arm mount line — the nose
                                             // tapers in from BOTH sides

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
pwr_z       = 16.5;   // connector centre height — RAISED so the body
                      // and solder cups pass above the PCA9685's
                      // entry-end right-angle pins (~z 8.6-11.4)

// --- arm-face hardware relief (underside) ---------------------------
// The arm's proud assembly screws sit a further 18 mm OUTBOARD of each
// outer mount hole (measured on the arm; the row reads
//   screw <18> hole <18> hole <seam> hole <18> hole <18> screw
// so the hardware lands 52 from the row centre). Screw heads at one
// end, a screw tip + nut at the other; BOTH spots get the full relief
// — a circular head recess in a locally thickened floor pad with an
// elongated nut through-slot in its middle — so the spine mounts
// either way round. The slot's extra length matches the +-2 mm
// seam-movement mount slots.
// Keep the seam screw's tip trimmed near-flush with its nut: a <=4 mm
// stack clears the PCA9685 header tails / the ESP32's RF can above.
hw_dx             = 52;    // ear_pair_pitch/2 + 9 + 18: outer mount
                           // hole at 34 from the row centre, screw a
                           // further 18 outboard
head_recess_d     = 18;    // covers screw head + washer
                           // (VERIFIED 2026-07-18: widest hardware <16)
head_recess_depth = 3.0;   // proudest head ~2.5 -> 0.5 air
head_pad_d        = 24;    // interior pad giving the recess its depth
nut_slot_w        = 9;     // M3 nut confirmed: 6.9 a/c + clearance
nut_slot_l        = 13;    // width + 4 mm travel (mount-slot match)

module spine_body() {
  difference() {
    union() {
    difference() {
        rounded_plate(box_l, box_w, box_h);
        // hollow: PCA9685 + plug bay cavity (raceway-side alignment)
        translate([pca_x, bay_y, floor_t])
            cube([esp_x - pca_x, inner_w, box_h]);
        // hollow: ESP32 cavity, centred on the mount line
        translate([esp_x, esp_bay_y, floor_t])
            cube([box_inner_l - entry_wall - (esp_x - pca_x), inner_w, box_h]);
        // hollow: USB cable channel from entry to the ESP32 bay mouth
        translate([pca_x, wall_t, floor_t])
            cube([esp_x - entry_wall - 2, usb_chan_w, box_h]);
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
        // servo lead slots in the LOW tier wall, 3 slots of 2 channels
        // each, open to the rim — leads drop in from above and cross
        // the curb to the headers. NOTE: the shell is EMITTED MIRRORED
        // (see sp_mirror at the bottom), so in the real part this low
        // wiring tier — trough, USB entry and these slots — is the
        // BACK face, matching the board's servo-header edge; the front
        // is one clean tall wall.
        for (i = [0 : 2])
            translate([pca_bx0 + 5.5 + i * 18, -0.1, floor_t + 3])
                cube([13, wall_t + 0.2, box_h]);
        // punch-hole ventilation on the tall back wall (the low front
        // tier is all slots and open trough — no punches needed there)
        for (zr = [0 : 1], xi = [0 : floor((box_l - 16) / punch_pitch_spine)]) {
            x = 8 + xi * punch_pitch_spine + (zr % 2) * punch_pitch_spine / 2;
            z = box_h - 14 + zr * 4;
            translate([x, box_w - wall_t - 0.1, z]) rotate([-90, 0, 0])
                cylinder(h = wall_t + 0.2, d = 2.2);
        }
        // ESP32 bay vents through both its (centred) side walls
        for (yv = [esp_bay_y - wall_t - 0.6, esp_bay_y + inner_w + 0.1],
             zr = [0, 1], xi = [0 : 7])
            translate([esp_x + 9.5 + xi * 5.2 + zr * 2.6, yv, 15 + zr * 4])
                rotate([-90, 0, 0]) cylinder(h = 4, d = 2.2);

        // ---- streamlining ------------------------------------------
        // low front tier: everything forward of the bay wall band drops
        // to 13 — the front wall only ever held slot sills and the
        // cable trough, not height. Wires still drop in from above.
        translate([-0.1, -0.1, 13])
            cube([esp_x + 1.9, 11.5, box_h]);
        // plan tapers: BOTH long faces sweep in to the centred nose
        // (rounded blends via offset)
        translate([0, 0, -0.5]) linear_extrude(box_h + 1)
            offset(r = 3) offset(delta = -3)
                polygon([[esp_x + 1.5, -0.1], [esp_x + 31.5, esp_bay_y - wall_t],
                         [box_l + 1, esp_bay_y - wall_t], [box_l + 1, -0.1]]);
        translate([0, 0, -0.5]) linear_extrude(box_h + 1)
            offset(r = 3) offset(delta = -3)
                polygon([[esp_x + 3.5, box_w + 0.1],
                         [esp_x + 29.5, esp_bay_y + inner_w + wall_t],
                         [box_l + 1, esp_bay_y + inner_w + wall_t],
                         [box_l + 1, box_w + 0.1]]);
        // rounded top edges (round-over cutters: corner bar minus rod)
        difference() {   // tall long wall: ELLIPTICAL round-over — the
                         // outer face starts curving 9 below the rim
                         // and sweeps up to crest exactly at the lid
                         // edge (raw y 43.4), so wall and lid meet on
                         // the curve's top
            translate([-0.1, box_w - 2.2, box_h - 9])
                cube([box_l + 0.2, 2.3, 9.1]);
            translate([-0.2, box_w - 2.2, box_h - 9])
                scale([1, 2.2, 9]) rotate([0, 90, 0])
                    cylinder(h = box_l + 0.4, r = 1, $fn = 64);
        }
        difference() {   // front tier edge, R3
            translate([-0.1, -0.1, 10]) cube([esp_x + 2, 3.2, 3.2]);
            translate([-0.2, 3, 10])
                rotate([0, 90, 0]) cylinder(h = esp_x + 2.2, r = 3);
        }
        difference() {   // entry-end top edge, R3
            translate([-0.1, 11.3, box_h - 3]) cube([3.2, 34.4, 3.1]);
            translate([3, 11.2, box_h - 3])
                rotate([-90, 0, 0]) cylinder(h = 34.6, r = 3);
        }
        // (the nose's curved crown is cut in the OUTER difference — it
        // has to shave the separately-unioned roof piece too)

        // inner raceway wall: a LOW straight curb (8 mm) — it only has
        // to keep the USB cable in its channel. Wires arrive from above
        // with the lid off and simply cross over it; no punched
        // openings needed, and the whole interior is hand-accessible.
        translate([pca_x, wall_t + usb_chan_w - 0.5, floor_t + 8])
            cube([esp_x - entry_wall - 2, wall_t + 1, box_h]);

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
    // USB-C plug bay (plug seats into the ESP32 across it). A LOW
    // straight wall shielding the plug bay; its middle is notched to
    // 6 mm where the PCA9685's horizontal end pins carry their I2C
    // Dupont housings straight across it (z 8.6-11.4).
    difference() {
        translate([pca_bx0 + pca_pcb_l + 1, esp_bay_y, floor_t])
            cube([wall_t + 2, bay_y + inner_w - esp_bay_y, 10]);
        translate([pca_bx0 + pca_pcb_l + 0.9, 19, floor_t + 6])
            cube([wall_t + 2.2, 18.5, 10]);
    }
    // nose roof: the bay's last stretch is closed by an integral 45°
    // sloped roof (interior ceiling from x = box_l - 11.4 at full
    // height down to the end wall) — the top tapers in at the ESP32
    // end. 45° prints support-free; every tall component (the D21/D22
    // Dupont shells, ~23.4) ends before the slope starts.
    intersection() {
        translate([box_l - 8.6, esp_bay_y - 0.1, box_h])
            rotate([0, 45, 0])
                cube([14, inner_w + 0.2, 14]);
        translate([box_l - 8.7, esp_bay_y - 0.2, 0])
            cube([8.8, inner_w + 0.4, box_h]);
    }
    // interior relief pads at BOTH pair centres: give the head recess
    // its depth whichever end faces the screw heads. 2.4 above the
    // floor — under the PCA9685 that leaves ~1.5 to the board's header
    // tails (PETG pad, harmless if they kiss); at the ESP32 end it
    // merges with the board seat pads.
    // interior relief pads at both hardware positions (18 outboard of
    // the outer mount holes): entry-end one merges with a PCA9685
    // standoff, nose-end one merges with the RF-can seat pad — both
    // harmless unions, the boards still seat at their design heights
    for (sx = [-1, 1])
        translate([ear_group_center + sx * hw_dx, box_w / 2, 0])
            cylinder(h = head_recess_depth + 1.4, d = head_pad_d);
    // PCA9685 corner standoffs (M2.5) — board datum sits pca_pin_clear
    // off the entry wall (right-angle pin room), 0.5 off the divider;
    // hole pattern centred across the bay width
    for (px = [-1, 1], py = [-1, 1])
        translate([pca_bx0 + (pca_pcb_l + 1) / 2 + px * pca_hole_dl / 2,
                   bay_y + inner_w / 2 + py * pca_hole_dw / 2,
                   floor_t])
            standoff(4, m25_pilot_d);
    // ESP32 seat — the board rides pins-DOWN (components up, antenna
    // under the lid's hex vent) on FOUR corner standoffs at its screw
    // holes, not rails: the underside stays open, so the hanging I2C
    // Dupont shells are reachable from the side with the board seated.
    // M2.5 screws into the pilot holes retain the board (no end stops
    // needed). Screw-hole spacing is a MEASURE-ME: 46.5 x 23.3 is the
    // common 30-pin devkit pattern — verify on the actual board.
    for (px = [0, 1], py = [0, 1])
        translate([esp_x + (esp32_pcb_l - esp_hole_dl) / 2
                       + px * esp_hole_dl,
                   esp_bay_y + (inner_w - esp_hole_dw) / 2
                       + py * esp_hole_dw,
                   floor_t])
            standoff(esp_rail_h, m25_pilot_d);
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
                        cylinder(h = box_h + 0.2, d = m3_free_d);
    // nose top: exterior is a CURVED quarter-round (R11.4) — the top
    // surface sweeps down and the end face continues the curve
    // tangentially below it (no facet crease). Cut HERE so it shaves
    // walls AND the unioned interior roof; the roof's 45° ceiling
    // stays underneath for printability.
    difference() {
        translate([box_l - 6.7, -0.1, box_h - 6.6])
            cube([7.2, box_w + 0.2, 6.8]);
        translate([box_l - 6.6, -0.2, box_h - 6.6])
            rotate([-90, 0, 0])
                cylinder(h = box_w + 0.4, r = 6.6, $fn = 96);
    }
    // symmetric relief at BOTH hardware positions (52 from the row
    // centre): circular head recess with an elongated nut through-slot
    // in its middle — either end deals with either the screw heads or
    // the screw tip + nut
    for (sx = [-1, 1]) {
        translate([ear_group_center + sx * hw_dx, box_w / 2, -0.1])
            cylinder(h = head_recess_depth + 0.1, d = head_recess_d);
        translate([ear_group_center + sx * hw_dx, box_w / 2, -0.1])
            hull()
                for (ox = [-(nut_slot_l - nut_slot_w) / 2,
                            (nut_slot_l - nut_slot_w) / 2])
                    translate([ox, 0, 0])
                        cylinder(h = 8.1, d = nut_slot_w);
    }
  }
}

punch_pitch_spine = 5;
esp_rail_h = 14.5;   // ESP32 rail height: board bottom at 16.5 —
                     // a 14mm Dupont housing below clears the floor
// Arm hole row (verified): pair-to-pair centre distance = 18/2 + 32 + 18/2.
ear_pair_pitch   = 50;
// Mount row CENTRED on the spine: the arm's seam sits mid-row, so a
// centred row keeps the spine spanning the two frame segments evenly
// (as fitted on the arm). The floating-end relief pad is clipped to
// the ESP32 bay so it can't shoulder into the USB plug bay floor.
ear_group_center = box_l / 2;

// Lid outline: the streamlined body only has a flat rim over the tall
// sections — a wide rectangle over the PCA run (front edge on the bay
// wall band, feet onto the low curb between the servo-lead windows;
// back edge at the round-over crest) jogging in to a narrower, centred
// rectangle over the ESP32 nose.
lid_x0 = 0;      lid_x1 = box_l - 8.6;         // ends at the nose roof
lid_y0 = 11.9;   lid_y1 = 43.4;                // PCA section edges
lid_ey0 = esp_bay_y - wall_t + 0.5;            // 6.2 — ESP section edges
lid_ey1 = esp_bay_y + inner_w + wall_t - 2.2;  // 37.7
lid_jx  = esp_x;                               // outline jog position
hex_cx = esp_x + 37;  hex_cy = box_w / 2;  // WiFi vent, over the RF can
hex_d  = 16;                               // across corners

// The shared motif at a finer pitch to suit the narrow lid; the '#'
// cells become the second-colour body (part="art"), the field around
// them is uniform fine punch holes on the same grid. Centred on the
// wide PCA section of the lid.
include <art_motif.scad>
art_pitch_s  = 1.45;
art_hole_s   = 1.05;
lid_margin_s = 4;
art_w_s = art_motif_cols * art_pitch_s;   // 34.8 along the spine
art_h_s = art_motif_rows * art_pitch_s;   // 23.2 across it
art_x0  = 26;
art_y0  = (lid_y0 + lid_y1 - art_h_s) / 2;

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
    ix_lo = -ceil((art_x0 - lid_x0 - lid_margin_s) / art_pitch_s);
    ix_hi = art_motif_cols - 1 + ceil((lid_x1 - art_x0 - art_w_s - lid_margin_s) / art_pitch_s);
    iy_lo = -ceil((art_y0 - lid_ey0 - lid_margin_s) / art_pitch_s);
    iy_hi = art_motif_rows - 1 + ceil((lid_y1 - art_y0 - art_h_s - lid_margin_s) / art_pitch_s);
    difference() {
        union() {
            // jogged plate: wide over the PCA run, narrow + centred
            // over the nose, corners rounded
            linear_extrude(lid_t_spine) offset(r = 2) offset(delta = -2)
                polygon([[lid_x0, lid_y0], [lid_jx, lid_y0],
                         [lid_jx + 3.5, lid_ey0],
                         [lid_x1, lid_ey0], [lid_x1, lid_ey1],
                         [lid_jx + 3.5, lid_ey1],
                         [lid_jx, lid_y1], [lid_x0, lid_y1]]);
            // locating skirt strips, dropping 5 inside the tall walls
            // (the nose back strip skips the ESP32's I2C Dupont block)
            translate([6.3, 14.0, -5]) cube([lid_jx - 18 - 6.3, 1.6, 5]);
            translate([6.3, 39.8, -5]) cube([lid_jx - 18 - 6.3, 1.6, 5]);
            translate([lid_jx + 3.5, esp_bay_y + 0.5, -5])
                cube([lid_x1 - lid_jx - 8.5, 1.6, 5]);
            // nose back strip in segments — gaps clear the I2C Dupont
            // shells standing on D21/D22 (x ~126-137) and GND/3V3
            for (xr = [[lid_jx + 14.5, lid_jx + 31]])
                translate([xr[0], esp_bay_y + inner_w - 2.1, -5])
                    cube([xr[1] - xr[0], 1.6, 5]);
            translate([6.3, 14.0, -5]) cube([1.6, 27.4, 5]);
            translate([lid_x1 - 4, esp_bay_y + 0.5, -5])
                cube([1.6, inner_w - 1, 5]);
            // deep feet onto the low curb, between the servo-lead
            // windows — they carry the lid's front edge over the PCA
            // bay, where the curb is only 8 tall
            for (xr = [[6.3, pca_bx0 + 4.5], [pca_bx0 + 19.5, pca_bx0 + 22.5],
                       [pca_bx0 + 37.5, pca_bx0 + 40.5],
                       [pca_bx0 + 55.5, pca_bx0 + 62]])
                translate([xr[0], 11.9, -15.8])
                    cube([xr[1] - xr[0], 1.6, 15.8]);
        }
        // through-cut for the second-colour art body
        translate([0, 0, -0.1]) scale([1, 1, 1.2]) spine_art_body();
        // hexagon WiFi/heat vent over the RF can
        translate([hex_cx, hex_cy, -0.1]) rotate([0, 0, 30])
            cylinder(h = lid_t_spine + 0.2, d = hex_d, $fn = 6);
        // fine punch-hole field on the motif grid, skipping solid cells
        // and the hexagon zone; bounds follow the jogged outline
        for (iy = [iy_lo : iy_hi], ix = [ix_lo : ix_hi]) {
            px = art_x0 + (ix + 0.5) * art_pitch_s;
            py = art_y0 + (iy + 0.5) * art_pitch_s;
            fy = px < lid_jx + 3.5 ? lid_y0 : lid_ey0;
            by = px < lid_jx ? lid_y1 : lid_ey1;
            if (!motif_solid(ix, iy) &&
                px > lid_x0 + lid_margin_s && px < lid_x1 - lid_margin_s &&
                py > fy + lid_margin_s && py < by - lid_margin_s &&
                norm([px - hex_cx, py - hex_cy]) > hex_d / 2 + 1.5)
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

// The shell is modelled with the wiring tier at y = 0 but EMITTED
// MIRRORED about the box centreline: in the real part all wire exits
// (trough, USB entry, servo-lead slots) face the BACK — the same side
// as the PCA9685's servo-header edge — and the front is a clean tall
// wall. World-y of the (mirrored) PCA bay, for the assembly model:
bay_yw = box_w - bay_y - inner_w;
module sp_mirror() {
    translate([0, box_w, 0]) mirror([0, 1, 0]) children();
}

plate_dx = 0;
plate_dy = 0;
translate([plate_dx, plate_dy, 0]) {
    if (part == "body") sp_mirror() spine_body();
    if (part == "lid") sp_mirror() spine_lid();
    if (part == "art_arm") sp_mirror() spine_art_body("A");
    if (part == "art_berry") sp_mirror() spine_art_body("B");
    // print-orientation plate variants (lid face-down, skirt up, art
    // coplanar) positioned beside the body for the Bambu project
    if (part == "lid_plate") spine_to_print() sp_mirror() spine_lid();
    if (part == "art_arm_plate") spine_to_print() sp_mirror() spine_art_body("A");
    if (part == "art_berry_plate") spine_to_print() sp_mirror() spine_art_body("B");
    if (part == "both") {
        sp_mirror() spine_body();
        translate([0, box_w + 12, 5]) sp_mirror() spine_lid();
        translate([0, box_w + 12, 5]) color("white") sp_mirror() spine_art_body("A");
        translate([0, box_w + 12, 5]) color("red") sp_mirror() spine_art_body("B");
    }
}
