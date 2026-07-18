// =====================================================================
// spine_assembly.scad — the electronics spine with mock components
// placed: PCA9685, ESP32, XT60 panel inlet, inline XT60 service
// disconnect, 6V feed wires and the USB-C run. Documentation model —
// nothing here is printed; render it to sanity-check fit and routing.
//
//   openscad spine_assembly.scad          (preview keeps the colours)
// =====================================================================

include <electronics_spine.scad>   // emits the body (default part)

// ---- PCA9685 (centred in its bay) -----------------------------------
pcb_x0 = pca_x + 0.5;
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
    translate([pcb_x0 + 1, pcb_y0 + 6, pcb_z0 + 1.6])
        cube([2.5, 15.2, 8.5]);    // free entry-end breakout row (pins up)
}
color("#1a4d1a")                   // old (dead-FET) terminal block
    translate([pcb_x0 + 28, pcb_y0 + pca_pcb_w - 8, pcb_z0 + 1.6])
        cube([10, 7.6, 10]);
color("#111111")                   // far breakout row + I2C plug shells
    translate([pcb_x0 + pca_pcb_l - 3.5, pcb_y0 + 5.5, pcb_z0 + 1.6])
        cube([2.5, 15.2, 14]);
color("silver") {                  // 16AWG solder joints: V+ and GND
    translate([pcb_x0 + 30, pcb_y0 + pca_pcb_w - 4, pcb_z0 + 2]) sphere(d = 3.2);
    translate([pcb_x0 + 36, pcb_y0 + pca_pcb_w - 4, pcb_z0 + 2]) sphere(d = 3.2);
}
color("dimgray")                   // 1000uF electrolytic
    translate([pcb_x0 + 45, pcb_y0 + pca_pcb_w - 5.5, pcb_z0 + 1.6])
        cylinder(h = 11.5, d = 8.5);

// ---- ESP32 devkit — UPSIDE DOWN (pins up) on the end pads -----------
esp_y0 = bay_y + (inner_w - esp32_pcb_w) / 2;
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
// the entry breakout row and the old terminal block; the servo header
// strip along the front edge stays unobstructed.
color("gold")
    translate([pca_x + 4, pcb_y0 + pca_pcb_w - 9.5, pcb_z0 + 1.7])
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
color("red") wire([[entry_wall, pwr_y - 3, pwr_z],
                   [pca_x + 3, pwr_y + 3, pcb_z0 + 9],
                   [pca_x + 5, pcb_y0 + pca_pcb_w - 6, pcb_z0 + 6.5],
                   [pca_x + 27, pcb_y0 + pca_pcb_w - 6, pcb_z0 + 6.5],
                   [pcb_x0 + 30, pcb_y0 + pca_pcb_w - 4, pcb_z0 + 3]]);
color("#111111") wire([[entry_wall, pwr_y + 3, pwr_z],
                       [pca_x + 3, pwr_y + 5, pcb_z0 + 10],
                       [pca_x + 5, pcb_y0 + pca_pcb_w - 8, pcb_z0 + 8.5],
                       [pca_x + 27, pcb_y0 + pca_pcb_w - 8, pcb_z0 + 8.5],
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
        wire([[esp_x + 4.3 + i * 2.54, esp_y0 + esp32_pcb_w - 1.7, esp_z0 + 15.8],
              [esp_x - 6, 40, 20],
              [pca_x + pca_pcb_l + 3, 37.5, 21],
              [pcb_x0 + pca_pcb_l - 2.2,
               pcb_y0 + 6.8 + i2c_pin[i] * 2.54, pcb_z0 + 15.8]], 1.6);

// ---- servo leads: 3-wire trios onto channels 0-5 --------------------
// Each MG996R lead (brown GND / red V+ / orange signal) presses onto a
// vertical 3-pin column: GND row nearest the board edge, V+ middle,
// signal inboard. Plugs stand upright side by side at 2.54 pitch from
// channel 0; the trios bend forward and leave 2-2-2 through the three
// front slots, crossing above the USB cable in the raceway.
hdr_x0 = pcb_x0 + (pca_pcb_l - 41) / 2;   // channel 0 pin column
module servo_lead(fx, tx) {
    cols = ["#553311", "#cc2222", "#cc6600"];   // brown / red / orange
    for (i = [0 : 2])
        color(cols[i])
            wire([[fx, pcb_y0 + 2 + 2.3 * i, pcb_z0 + 14.5],
                  [(fx + tx) / 2, 12, 13 - i],
                  [tx - 4 + 1.3 * i, 6, 8.5],
                  [tx - 4 + 1.3 * i, -6, 7.5]], 1.6);
}
for (c = [0 : 5]) {
    color("#111111")                          // plug housing on the pins
        translate([hdr_x0 + c * 2.54 + 0.1, pcb_y0 + 0.7, pcb_z0 + 3.5])
            cube([2.35, 8, 12]);
    servo_lead(hdr_x0 + c * 2.54 + 1.27,
               [18.5, 18.5, 36.5, 36.5, 54.5, 54.5][c] + (c % 2 == 0 ? -2 : 2));
}
