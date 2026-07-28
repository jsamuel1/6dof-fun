// =====================================================================
// keel_assembly.scad — the keel's SERVICE VIEW: the click-off base
// with every board, connector and cable run placed. This is the layer
// you see with the base popped off the shell (drawers, WAGO rails and
// the transom power wall all ride the base); the comb floats at its
// installed height in the (absent) shell grooves. Documentation model —
// nothing here is printed.
//
//   openscad keel_assembly.scad     (F5 preview keeps the colours)
// =====================================================================

include <keel_base.scad>
part = "none";                    // suppress keel_base's own emission

module wire(pts, d = 1.8) {
    for (i = [0 : len(pts) - 2])
        hull() {
            translate(pts[i]) sphere(d = d);
            translate(pts[i + 1]) sphere(d = d);
        }
}
module tag(t, pos, s = 3.4, c = "#222222", rot = 0)
    color(c) translate(pos) rotate([0, 0, rot])
        linear_extrude(0.6) text(t, size = s, halign = "center");

// ---- the base itself -------------------------------------------------
color("#c8c33a") keel_floor();

// ---- power chamber components ---------------------------------------
color("#2d6a2d")                  // buck (65 x 48) on its sled
    translate([-117, -24, floor_h + sled_t + 4]) cube([65, 48, 1.6]);
color("dimgray")                  // buck inductor + caps, mock
    translate([-100, -10, floor_h + 7.2]) cube([18, 16, 9]);
tag("BUCK", [-80, -14, 14]);
tag("6V OUT", [-62, 10, 14], 3, "#cc2222");
color("#3a3a8c")                  // HUSB238 (USB-C PD sink) on the shelf
    translate([-116, -20, 20.5]) cube([10, 18, 1.6]);
tag("HUSB238", [-100, -26, 22], 3, "#3a3a8c");
color("#8c3a3a")                  // Pololu ORing ideal-diode pair
    translate([-116, 2, 20.5]) cube([10, 15, 1.6]);
tag("ORing", [-100, 12, 22], 3, "#8c3a3a");

// transom connectors (ride the base's power wall)
color("#111111")                  // 12V barrel jack
    translate([-121, jack_y, jack_z]) rotate([0, 90, 0]) cylinder(h = 8, d = 11);
tag("12V IN", [-104, -40, 24], 3.4);
color("silver") {                 // two USB-C panel extension flanges
    translate([-121, usbc_pd_y - 6, jack_z - 3.5]) cube([4, 12, 7]);
    translate([-121, usbc_srv_y - 6, jack_z - 3.5]) cube([4, 12, 7]);
}
tag("USB-C PD", [-104, 34, 24], 3.4);

// ---- WAGO junction rails (on the base) -------------------------------
// two angled lanes: + rail aft, - rail fore; 2x 221-415 per lane
for (r = [0 : 1], w = [0 : 1])
    color(r == 0 ? "#cc4444" : "#444444")
        translate([jt_x - jt_lane_dx / 2 + r * jt_lane_dx - 6,
                   -29 + w * (wago_w + 1), floor_h + 2])
            rotate([0, -jt_angle, 0]) cube([wago_h, wago_w, wago_l]);
tag("+ RAIL", [-48, -44, 20], 3.2, "#cc4444");
tag("- RAIL", [-16, -44, 20], 3.2, "#444444");

// ---- coupler comb at its installed height ----------------------------
// latch bar omitted from this view (shown open/serviced) so the
// channels, plugs and WAGO lanes below stay visible
color("#cc3333") translate([jt_x, 0, comb_y]) coupler_comb();
// six Dupont pairs in the channels: male (aft, captive) + female (fore)
for (i = [0 : 5]) {
    dy = (i - 2.5) * comb_pitch;
    color("#181818")
        translate([jt_x - 15.5, dy - 3.1, comb_y + 3]) cube([9, 6.2, 7.4]);
    color("#303030")
        translate([jt_x - 6, dy - 3.2, comb_y + 3]) cube([14.5, 6.4, 7.5]);
}
tag("COMB", [-30, 40, 34], 3.4, "#cc3333");

// ---- drawers (ride the base) -----------------------------------------
color("#cc3333") {
    translate([7, -drw_z - (drw_w - 6) / 2, floor_h]) drawer_esp();
    translate([7,  drw_z - (drw_w - 6) / 2, floor_h]) drawer_pca();
}
color("#233a5e")                  // ESP32 on its side, pins inboard
    translate([16, -drw_z + 6, floor_h + sled_t]) cube([52, 1.6, 28.9]);
tag("ESP32", [42, -50, 34], 3.4, "#233a5e");
color("#2255aa")                  // PCA9685 flat, servo row outboard
    translate([14, drw_z - 12, floor_h + sled_t + pca_seat_h]) cube([62.5, 25.4, 1.6]);
color("#181818")                  // its 16-channel header row, outboard
    translate([24, drw_z + 8, floor_h + 5.6]) cube([41, 5, 8]);
tag("PCA9685", [42, 50, 34], 3.4, "#2255aa");

// =====================================================================
// CABLE RUNS
// =====================================================================
// 12V jack -> ORing; PD input -> HUSB238 -> ORing; ORing -> buck IN
color("red")     wire([[-113, jack_y, jack_z], [-112, -2, 21.5]], 2.2);
color("#111111") wire([[-113, jack_y - 3, jack_z], [-113, -6, 21.5]], 2.2);
color("#555555") wire([[-117, usbc_pd_y, jack_z], [-113, -14, 21.5]], 3);
color("red")     wire([[-107, 6, 21.5], [-104, -6, 12], [-104, -14, 9.5]], 2.2);
color("#111111") wire([[-107, 12, 21.5], [-102, 0, 12], [-102, -10, 9.5]], 2.2);
// buck 6V OUT -> through the chamber->junction port -> WAGO feed entries
color("red")     wire([[-56, -6, 9], [-48, -4, 8], [-40, -22, 13]], 2.4);
color("#111111") wire([[-56, 2, 9], [-46, 0, 8], [-21, -22, 13]], 2.4);
tag("6V FEED", [-46, -34, 4], 3, "#cc2222");
// WAGO lanes -> servo power pairs rising to the comb drop slots
for (i = [0 : 5]) {
    dy = (i - 2.5) * comb_pitch;
    color("red")     wire([[-39, min(dy, 26) - 2, 16], [-39, dy, comb_y + 1]], 1.4);
    color("#111111") wire([[-20.5, min(dy, 26) - 1, 16], [-38, dy + 1.5, comb_y + 1]], 1.4);
}
// PCA drawer pigtails: signal bundle through the 19x14 service window
// to the comb's male plugs
color("#cc6600") wire([[30, drw_z + 10, 12], [-4, 22, 10],
                       [-16, 8, comb_y - 2], [-20, 0, comb_y + 4]], 3.4);
tag("6x signal", [8, 34, 16], 3, "#cc6600");
// WAGO VIN pair + I2C to the ESP32 drawer through the 14x12 window
color("red")     wire([[-39, -27, 14], [-8, -14, 8], [10, -22, 8]], 1.8);
color("#111111") wire([[-20.5, -27, 14], [-6, -16, 8], [12, -24, 8]], 1.8);
color("#8844cc") wire([[28, drw_z + 8, 10], [-2, 16, 8], [-4, -14, 9],
                       [14, -22, 11]], 2.6);
tag("I2C", [8, -6, 12], 3, "#8844cc");
// USB-C service extension: transom -> chamber -> tray gully -> ESP
// window -> tunnel -> drawer face (the 200mm run; plug ends thread the
// enlarged ports)
color("#555555") wire([[-117, usbc_srv_y, jack_z], [-70, 20, 6],
                       [-48, 4, 8], [-30, 0, 6], [-8, -14, 7],
                       [20, -30, 6], [70, -30, 12], [79, -27, 14]], 3.2);
tag("USB-C service ext", [-64, 42, 10], 3.2, "#555555");
// servo harness: six trios leave the comb's female plugs and rise
// through the lid egress bore (bushing shown at height)
for (i = [0 : 5]) {
    dy = (i - 2.5) * comb_pitch;
    color(i % 2 == 0 ? "#cc6600" : "#553311")
        wire([[jt_x + 9, dy, comb_y + 6], [-17, dy / 3, 40], [-17, 0, 52]], 2.6);
}
color("aqua") translate([egress_x, 0, H - lid_t - 1.6]) edge_bushing();
tag("HARNESS UP THRU LID", [-17, -46, 44], 3.4);
