// =====================================================================
// keel_assembly.scad — the keel's SERVICE VIEW: the click-off base
// with every board, connector and cable run placed. This is the layer
// you see with the base popped off the shell (drawers, WAGO clamps and
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
    translate([-143, -24, floor_h + sled_t + 4]) cube([65, 48, 1.6]);
color("dimgray")                  // buck inductor + caps, mock
    translate([-126, -10, floor_h + 7.2]) cube([18, 16, 9]);
tag("BUCK", [-106, -14, 14]);
tag("6V OUT", [-88, 10, 14], 3, "#cc2222");
color("#3a3a8c")                  // HUSB238 (USB-C PD sink) on the shelf
    translate([-142, -20, 20.5]) cube([10, 18, 1.6]);
tag("HUSB238", [-126, -26, 22], 3, "#3a3a8c");
color("#8c3a3a")                  // Pololu ORing ideal-diode pair
    translate([-142, 2, 20.5]) cube([10, 15, 1.6]);
tag("ORing", [-126, 12, 22], 3, "#8c3a3a");

// transom connectors (ride the base's power wall)
color("#111111")                  // 12V barrel jack
    translate([-147, jack_y, jack_z]) rotate([0, 90, 0]) cylinder(h = 8, d = 11);
tag("12V IN", [-130, -40, 24], 3.4);
color("silver") {                 // two USB-C panel extension flanges
    translate([-147, usbc_pd_y - 6, jack_z - 3.5]) cube([4, 12, 7]);
    translate([-147, usbc_srv_y - 6, jack_z - 3.5]) cube([4, 12, 7]);
}
tag("USB-C PD", [-130, 34, 24], 3.4);

// ---- three-tier WAGOs (v3.11) ----------------------------------------
// baseplate hub pair: the supplies' 6V egress, under the comb,
// entries FORE into 31mm of floor corridor
for (sy = [-1, 1])
    color(sy < 0 ? "#cc4444" : "#444444")
        translate([-60, sy * 17 - 15, floor_h + 0.2])
            cube([18.6, 30, wago_h]);
tag("HUB PAIR", [-52, -44, 14], 3, "#cc4444");
// comb servo stations: 2x 221-415 abreast per wing, ENTRIES OUTBOARD
// into the ~14mm corridor between entry face and tray wall
for (sy = [-1, 1], wx = [-1, 1])
    color(sy < 0 ? "#cc4444" : "#444444")
        translate([jt_x + wx * 15.8 - 15, sy * 24.5 - 9.3, comb_y + 3.2])
            cube([30, 18.6, wago_h]);
tag("SERVO + x2", [-43, -54, 30], 3, "#cc4444");
tag("SERVO - x2", [-43, 50, 30], 3, "#444444");

// ---- coupler comb (v3.11: the lift-out junction) ---------------------
// latch bar omitted (shown open/serviced)
color("#cc3333") translate([jt_x, 0, comb_y]) coupler_comb();
// THREE 2-pin signal pairs: male (aft, captive) + female (fore) — two
// servos' signals per plug; power never touches a Dupont
for (i = [0 : 2]) {
    dy = (i - 1) * comb_pitch;
    color("#181818")
        translate([jt_x - 15.5, dy - 3.1, comb_y + 3]) cube([9, 6.2, 5.2]);
    color("#303030")
        translate([jt_x - 6, dy - 3.2, comb_y + 3]) cube([14.5, 6.4, 5.3]);
}
tag("COMB", [-78, 0, 34], 3.4, "#cc3333", 90);

// ---- THE drawer (v3.8: one drawer, both boards, rides the base) ------
color("#cc3333") translate([7, 0, floor_h]) drawer_boards();
color("#233a5e")                  // ESP32 on its side in its lane
    translate([16, esp_lane - 0.8, floor_h + sled_t]) cube([52, 1.6, 28.9]);
tag("ESP32", [42, -50, 34], 3.4, "#233a5e");
color("#2255aa")                  // PCA9685 flat in its lane, servo row outboard
    translate([14, pca_lane - 12.7, floor_h + sled_t + pca_seat_h])
        cube([62.5, 25.4, 1.6]);
color("#181818")                  // its 16-channel header row, outboard
    translate([24, pca_lane + 7, floor_h + 5.6]) cube([41, 5, 8]);
tag("PCA9685", [42, 50, 34], 3.4, "#2255aa");
for (sx = [-1, 1])                // drawer pair: board power
    color(sx < 0 ? "#cc4444" : "#444444")
        translate([7 + sled_l / 2 + sx * 17 - wago_w / 2, -11.4,
                   floor_h + sled_t + 0.2])
            cube([wago_w, wago_l, wago_h]);
tag("BOARD PAIR", [43, 2, 16], 3, "#cc4444");

// =====================================================================
// CABLE RUNS
// =====================================================================
// 12V jack -> ORing; PD input -> HUSB238 -> ORing; ORing -> buck IN
color("red")     wire([[-139, jack_y, jack_z], [-138, -2, 21.5]], 2.2);
color("#111111") wire([[-139, jack_y - 3, jack_z], [-139, -6, 21.5]], 2.2);
color("#555555") wire([[-143, usbc_pd_y, jack_z], [-139, -14, 21.5]], 3);
color("red")     wire([[-133, 6, 21.5], [-130, -6, 12], [-130, -14, 9.5]], 2.2);
color("#111111") wire([[-133, 12, 21.5], [-128, 0, 12], [-128, -10, 9.5]], 2.2);
// buck 6V OUT -> chamber port -> along the centre gap -> U-turn into
// the hub pair's FORE entries
color("red")     wire([[-82, -6, 9], [-66, -1, 7], [-36, -1, 7],
                       [-33, -8, 7], [-38, -14, 7]], 2.4);
color("#111111") wire([[-82, 2, 9], [-64, 1, 7], [-34, 3, 7],
                       [-33, 10, 7], [-38, 16, 7]], 2.4);
tag("6V FEED", [-70, -30, 4], 3, "#cc2222");
// hub jumpers: rise through the comb's wing slots into the corridor
// entries (unclip these two to lift the whole comb out safely)
color("red")     wire([[-40, -20, 7], [-35, -38, 10], [-35, -38, comb_y + 6],
                       [-40, -36, comb_y + 6]], 2);
color("#111111") wire([[-40, 20, 7], [-35, 38, 10], [-35, 38, comb_y + 6],
                       [-40, 36, comb_y + 6]], 2);
tag("jumpers", [-20, 40, 20], 2.8, "#cc2222");
// arm servo power: 6x +/- tails drop into the outboard corridors and
// clip straight into the station entries
for (i = [0 : 5]) {
    color("red")     wire([[-70 + i * 10, -35, comb_y + 6],
                           [-50 + i * 4, -30, 42], [-27, 0, 52]], 1.5);
    color("#111111") wire([[-70 + i * 10, 35, comb_y + 6],
                           [-50 + i * 4, 30, 42], [-27, 0, 52]], 1.5);
}
tag("tails: corridor", [-43, -60, 24], 2.8, "#cc2222");
// board power: hub pair -> ESP window -> the drawer's BOARD PAIR (the
// drawer's only power umbilical)
color("red")     wire([[-38, -12, 7], [-8, -14, 6], [26, -8, 8]], 2);
color("#111111") wire([[-38, 14, 7], [-6, 4, 6], [28, -4, 8]], 2);
// board power taps off the drawer pair to each board
color("red")     wire([[30, -6, 12], [18, esp_lane + 2, 10]], 1.6);
color("#111111") wire([[46, -6, 12], [40, pca_lane - 10, 8]], 1.6);
color("#8844cc") wire([[20, pca_lane - 10, 8], [18, 2, 10],
                       [18, esp_lane + 2, 12]], 2.6);
tag("I2C rides the drawer", [30, 2, 14], 3, "#8844cc");
// USB-C service extension: transom -> chamber -> tray gully -> ESP
// window -> tunnel -> drawer face (the 200mm run; plug ends thread the
// enlarged ports)
color("#555555") wire([[-143, usbc_srv_y, jack_z], [-96, 20, 6],
                       [-74, 4, 8], [-43, -4, 6], [-8, -14, 7],
                       [20, -30, 6], [70, esp_lane - 8, 12], [79, esp_lane, 14]], 3.2);
tag("USB-C service ext", [-90, 42, 10], 3.2, "#555555");
// signal harness: three 2-pin leads leave the female plugs and rise
// with the power wires through the lid egress bore
for (i = [0 : 2]) {
    dy = (i - 1) * comb_pitch;
    color("#cc6600")
        wire([[jt_x + 9, dy, comb_y + 6], [-27, dy / 3, 40], [-27, 0, 52]], 2.2);
}
color("aqua") translate([egress_x, 0, H - lid_t - 1.6]) edge_bushing();
tag("HARNESS UP THRU LID", [-27, -46, 44], 3.4);
