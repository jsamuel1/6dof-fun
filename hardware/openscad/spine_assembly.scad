// =====================================================================
// spine_assembly.scad — the electronics spine with mock components
// placed: PCA9685, ESP32, XT60 panel inlet, inline XT60 service
// disconnect, 6V feed wires and the USB-C run. Documentation model —
// nothing here is printed; render it to sanity-check fit and routing.
//
//   openscad spine_assembly.scad          (preview keeps the colours)
// =====================================================================

include <electronics_spine.scad>   // emits the body (default part)

// ---- PCA9685 (pin-clearance off the entry wall) ---------------------
pcb_x0 = pca_bx0 + 0.5;
pcb_y0 = bay_y + (inner_w - pca_pcb_w) / 2;
pcb_z0 = floor_t + 4;              // standoff tops
color("forestgreen")
    translate([pcb_x0, pcb_y0, pcb_z0])
        cube([pca_pcb_l, pca_pcb_w, 1.6]);
color("#222222") {                 // 16-channel servo headers, front edge
    translate([pcb_x0 + (pca_pcb_l - 41) / 2, pcb_y0 + 0.6, pcb_z0 + 1.6])
        cube([41, 8, 8]);
    translate([pcb_x0 + 27, pcb_y0 + pca_pcb_w / 2 - 3, pcb_z0 + 1.6])
        cube([7, 6, 1.2]);         // PCA9685 chip
    // RIGHT-ANGLE 6-pin headers at both board ends, pins horizontal
    // out past the edges (~6 mm at ~z 10)
    translate([pcb_x0, pcb_y0 + 5.5, pcb_z0 + 1.6]) cube([2.5, 15.2, 2.5]);
    translate([pcb_x0 + pca_pcb_l - 2.5, pcb_y0 + 5.5, pcb_z0 + 1.6])
        cube([2.5, 15.2, 2.5]);
}
color("silver") {                  // the horizontal pin combs
    translate([pcb_x0 - 6, pcb_y0 + 5.5, 9.7]) cube([6.2, 15.2, 0.7]);
    translate([pcb_x0 + pca_pcb_l - 0.2, pcb_y0 + 5.5, 9.7])
        cube([6.4, 15.2, 0.7]);
}
color("#333366")                   // I2C Dupont housings, plugged on
    translate([pcb_x0 + pca_pcb_l + 0.4, pcb_y0 + 5.3, 8.5])
        cube([14, 15.4, 3.0]);     // horizontally over the notched divider
color("#1a4d1a")                   // old (dead-FET) terminal block
    translate([pcb_x0 + 28, pcb_y0 + pca_pcb_w - 8, pcb_z0 + 1.6])
        cube([10, 7.6, 10]);
color("silver") {                  // 16AWG solder joints: V+ and GND
    translate([pcb_x0 + 30, pcb_y0 + pca_pcb_w - 4, pcb_z0 + 2]) sphere(d = 3.2);
    translate([pcb_x0 + 36, pcb_y0 + pca_pcb_w - 4, pcb_z0 + 2]) sphere(d = 3.2);
}
color("dimgray")                   // 1000uF electrolytic
    translate([pcb_x0 + 45, pcb_y0 + pca_pcb_w - 5.5, pcb_z0 + 1.6])
        cylinder(h = 11.5, d = 8.5);

// ---- ESP32 devkit — UPSIDE DOWN (pins up) on the end pads -----------
esp_y0 = esp_bay_y + (inner_w - esp32_pcb_w) / 2;
esp_z0 = floor_t + esp_pad_h + 3.2;   // board underside: pads + can height
color("#233a5e")
    translate([esp_x, esp_y0, esp_z0])
        cube([esp32_pcb_l, esp32_pcb_w, 1.6]);
color("silver") {                  // RF can BELOW the board, on its pad
    translate([esp_x + esp32_pcb_l - 18, esp_y0 + (esp32_pcb_w - 16) / 2,
               esp_z0 - 3.2])
        cube([16, 16, 3.2]);
    translate([esp_x - 1.5, esp_y0 + esp32_pcb_w / 2 - 4.5, esp_z0 - 3.2])
        cube([7, 9, 3.2]);         // USB-C receptacle, faces the plug bay
}
color("#222222")                   // pin rows standing UP off the board
    for (y = [esp_y0 + 0.6, esp_y0 + esp32_pcb_w - 3.1])
        translate([esp_x + 1, y, esp_z0 + 1.6])
            cube([esp32_pcb_l - 2, 2.5, 6]);
// I2C hookup: 4-way Dupont block pressed onto the up-facing pins
// (GND / 3V3 / D21 SDA / D22 SCL, back row, divider end) — reachable
// from above even with the board installed
color("#333366")
    translate([esp_x + 3, esp_y0 + esp32_pcb_w - 3.2, esp_z0 + 1.6])
        cube([10.2, 2.9, 14]);

// ---- XT60 power inlet (panel mount, entry wall) ---------------------
pwr_y = bay_y + inner_w / 2;
color("gold") {
    translate([0.3, pwr_y - pwr_pock_w / 2 + 0.5, pwr_z - pwr_pock_h / 2 + 0.5])
        cube([pwr_panel_t + 1.4, pwr_pock_w - 1, pwr_pock_h - 1]);  // flange
    translate([-6, pwr_y - pwr_cut_w / 2 + 0.3, pwr_z - pwr_cut_h / 2 + 0.3])
        cube([entry_wall + 8, pwr_cut_w - 0.6, pwr_cut_h - 0.6]);   // body
}

// ---- inline XT60 service disconnect ---------------------------------
// Lengthwise in the clear band along the board's back edge, between
// the entry breakout header and the old terminal block; the servo
// header strip along the front edge stays unobstructed.
color("gold")
    translate([pcb_x0 + 3.5, pcb_y0 + pca_pcb_w - 9.5, pcb_z0 + 1.7])
        cube([24, 8.2, 8]);

// ---- 6V feed: panel tails -> inline pair -> V+/GND through-holes ----
module wire(pts, d = 1.8) {
    for (i = [0 : len(pts) - 2])
        hull() {
            translate(pts[i]) sphere(d = d);
            translate(pts[i + 1]) sphere(d = d);
        }
}
// supply side, outside the entry wall: the converter lead's mating
// XT60 plugged into the panel inlet, 16AWG pair heading down-arm
color("gold")
    translate([-13, pwr_y - 4, pwr_z - 4]) cube([13.2, 8, 8]);
color("red") wire([[-12, pwr_y - 2, pwr_z], [-24, pwr_y - 2, pwr_z - 2],
                   [-32, pwr_y - 1, pwr_z - 6]], 2.4);
color("#111111") wire([[-12, pwr_y + 2, pwr_z], [-24, pwr_y + 2, pwr_z - 2],
                       [-32, pwr_y + 3, pwr_z - 6]], 2.4);
// internal run drops from the raised inlet, passing ABOVE the board's
// entry-end pins, then along the back band via the inline pair
color("red") wire([[12, pwr_y - 3, pwr_z],
                   [pca_bx0 + 2, pwr_y + 3, 13.5],
                   [pcb_x0 + 2, pcb_y0 + pca_pcb_w - 6, pcb_z0 + 6.5],
                   [pcb_x0 + 21, pcb_y0 + pca_pcb_w - 6, pcb_z0 + 6.5],
                   [pcb_x0 + 30, pcb_y0 + pca_pcb_w - 4, pcb_z0 + 3]]);
color("#111111") wire([[12, pwr_y + 3, pwr_z],
                       [pca_bx0 + 2, pwr_y + 5, 14.5],
                       [pcb_x0 + 2, pcb_y0 + pca_pcb_w - 8, pcb_z0 + 8.5],
                       [pcb_x0 + 21, pcb_y0 + pca_pcb_w - 8, pcb_z0 + 8.5],
                       [pcb_x0 + 36, pcb_y0 + pca_pcb_w - 4, pcb_z0 + 3]]);

// ---- USB-C run: entry port -> raceway -> plug bay -> ESP32 ----------
color("#555555") {
    translate([-6, wall_t + usb_chan_w / 2, floor_t + 2.2])
        rotate([0, 90, 0]) cylinder(h = esp_x - bay_gap + wall_t + 9, d = 4);
    translate([esp_x - 11.5, esp_y0 + esp32_pcb_w / 2 - 5, esp_z0 - 4.3])
        cube([10.5, 10, 5.4]);     // USB-C plug body in the bay
    // cable turning from the raceway through the mouth to the plug
    wire([[esp_x - bay_gap + wall_t + 7, wall_t + usb_chan_w / 2, floor_t + 2.2],
          [esp_x - 8, bay_y + 6, floor_t + 3],
          [esp_x - 6.5, esp_y0 + esp32_pcb_w / 2, esp_z0 - 1.6]], 4);
}

// ---- I2C harness: ESP32 pins (up) -> PCA9685 far breakout row -------
// Four jumpers, coloured as wired on the bench (see hardware/wiring.md):
//   brown  GND    -> PCA GND   (pin 1 of the 6-pin row)
//   orange SCL    -> ESP32 D22 / PCA SCL (pin 3)
//   yellow SDA    -> ESP32 D21 / PCA SDA (pin 4)
//   green  3V3    -> PCA VCC   (pin 5)
// They leave the Dupont block on the ESP32's up-facing pins, run high
// across the plug bay, over the low divider, and press onto the
// PCA9685's divider-end breakout row.
i2c_cols = ["#7a4a21", "#e07000", "#e8c520", "#2e9e3e"];
i2c_pin  = [0, 2, 3, 4];   // positions on the PCA's 6-pin row
for (i = [0 : 3])
    color(i2c_cols[i])
        // flat 4-wide ribbon: >=1.8 lateral spacing at every waypoint
        // (wire dia 1.5). Leaves the horizontal housings on the PCA's
        // right-angle pins (z ~10, over the notched divider and above
        // the USB plug), swings up through the plug bay onto the
        // ESP32's up-facing pin block.
        wire([[pcb_x0 + pca_pcb_l + 14.6,
               pcb_y0 + 6.8 + i2c_pin[i] * 2.54, 10.1],
              [esp_x - 3, 27 + 2.2 * (i - 1.5), 15],
              [esp_x + 1.5 + 1.9 * (i - 1.5), 31 + 1.5 * (i - 1.5), 20.5],
              [esp_x + 4.3 + i * 2.54, esp_y0 + esp32_pcb_w - 1.7,
               esp_z0 + 15.8]], 1.5);

// ---- destination labels (floating, read from above) -----------------
module tag(t, pos, s = 2.4, c = "#222222", rot = 0)
    color(c) translate(pos) rotate([0, 0, rot])
        linear_extrude(0.6) text(t, size = s, halign = "left");
// PCA9685 servo channels: numbers above the six plugs
for (c = [0 : 5])
    tag(str(c), [hdr_x0 + c * 2.54 + 0.4, pcb_y0 + 10, 24], 2.2, "white");
tag("CH", [hdr_x0 - 4.5, pcb_y0 + 10, 24], 2.2, "white");
// PCA9685 6-pin breakout row (divider end), pin 1 nearest the servo
// headers; dots colour-matched to the wires on the used pins
pca_pin_names = ["1 GND", "2 OE", "3 SCL", "4 SDA", "5 VCC", "6 V+"];
pca_pin_used  = [0, undef, 1, 2, 3, undef];   // index into i2c_cols
for (p = [0 : 5]) {
    tag(pca_pin_names[p],
        [pcb_x0 + pca_pcb_l - 15.5, pcb_y0 + 5.9 + p * 2.54, 24], 2.0,
        pca_pin_used[p] == undef ? "#777777" : i2c_cols[pca_pin_used[p]]);
    if (pca_pin_used[p] != undef)
        color(i2c_cols[pca_pin_used[p]])
            translate([pcb_x0 + pca_pcb_l + 4,
                       pcb_y0 + 6.8 + p * 2.54, 24])
                cylinder(h = 0.6, d = 1.8);
}
// ESP32 header pins carrying the I2C block (back row, divider end)
esp_pin_names = ["GND", "3V3", "D21 SDA", "D22 SCL"];
for (i = [0 : 3])
    tag(esp_pin_names[i],
        [esp_x + 5.2 + i * 2.54, esp_y0 + esp32_pcb_w + 2, 24.4], 2.0,
        i2c_cols[i], 90);
// power attachments
tag("V+",  [pcb_x0 + 28.5, pcb_y0 + pca_pcb_w - 1, 24], 2.2, "#cc2222");
tag("GND", [pcb_x0 + 34.5, pcb_y0 + pca_pcb_w - 1, 24], 2.2, "#222222");
tag("6V IN (XT60)", [-30, pwr_y + 7, 18], 2.4);
tag("USB-C", [esp_x - 13, esp_y0 - 3.5, 20], 2.2);

// ---- servo leads: 3-wire trios onto channels 0-5 --------------------
// Each MG996R lead (brown GND / red V+ / orange signal) presses onto a
// vertical 3-pin column: GND row nearest the board edge, V+ middle,
// signal inboard. Plugs stand upright side by side at 2.54 pitch from
// channel 0; the trios bend forward and leave 2-2-2 through the three
// front slots, crossing above the USB cable in the raceway.
hdr_x0 = pcb_x0 + (pca_pcb_l - 41) / 2;   // channel 0 pin column
module servo_lead(fx, tx) {
    // three wires modelled at their real ~1.3 dia, held 1.5 apart at
    // every waypoint — the flat ribbon twists from the vertical pin
    // column to lie flat through the slot, never merging
    cols = ["#553311", "#cc2222", "#cc6600"];   // brown / red / orange
    for (i = [0 : 2])
        color(cols[i])
            wire([[fx, pcb_y0 + 1.8 + 2.54 * i, pcb_z0 + 14.5],
                  [(fx + tx) / 2 + 1.5 * (i - 1), 12, 12.5 - 1.5 * (i - 1)],
                  [tx - 4.5 + 1.5 * i, 6, 8.5],
                  [tx - 4.5 + 1.5 * i, -6, 7.5]], 1.3);
}
for (c = [0 : 5]) {
    color("#111111")                          // plug housing on the pins
        translate([hdr_x0 + c * 2.54 + 0.1, pcb_y0 + 0.7, pcb_z0 + 3.5])
            cube([2.35, 8, 12]);
    servo_lead(hdr_x0 + c * 2.54 + 1.27,
               pca_bx0 + [12, 12, 30, 30, 48, 48][c] + (c % 2 == 0 ? -2 : 2));
}
