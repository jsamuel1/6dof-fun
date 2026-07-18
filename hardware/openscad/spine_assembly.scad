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
color("dimgray")                   // 1000uF electrolytic
    translate([pcb_x0 + 45, pcb_y0 + pca_pcb_w - 5.5, pcb_z0 + 1.6])
        cylinder(h = 11.5, d = 8.5);

// ---- ESP32 devkit (on the tapered rails) ----------------------------
esp_y0 = bay_y + (inner_w - esp32_pcb_w) / 2;
esp_z0 = floor_t + esp32_pin_h;    // rail tops
color("#233a5e")
    translate([esp_x, esp_y0, esp_z0])
        cube([esp32_pcb_l, esp32_pcb_w, 1.6]);
color("silver") {                  // RF can, antenna end up-arm
    translate([esp_x + esp32_pcb_l - 18, esp_y0 + (esp32_pcb_w - 16) / 2,
               esp_z0 + 1.6])
        cube([16, 16, 3.1]);
    translate([esp_x - 1.5, esp_y0 + esp32_pcb_w / 2 - 4.5, esp_z0 + 1.6])
        cube([7, 9, 3.2]);         // USB-C receptacle, faces the plug bay
}
color("#222222")                   // pin rows hanging outside the rails
    for (y = [esp_y0 + 0.6, esp_y0 + esp32_pcb_w - 3.1])
        translate([esp_x + 1, y, floor_t + 2])
            cube([esp32_pcb_l - 2, 2.5, esp32_pin_h - 2]);

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
    translate([esp_x - 11.5, esp_y0 + esp32_pcb_w / 2 - 5, esp_z0 + 0.6])
        cube([10.5, 10, 5.4]);     // USB-C plug body in the bay
    // cable turning from the raceway through the mouth to the plug
    wire([[esp_x - bay_gap + wall_t + 7, wall_t + usb_chan_w / 2, floor_t + 2.2],
          [esp_x - 8, bay_y + 6, floor_t + 4],
          [esp_x - 6.5, esp_y0 + esp32_pcb_w / 2, esp_z0 + 3]], 4);
}

// ---- I2C ribbon: divider notch, far breakout row --------------------
color("#8844cc") wire([[esp_x + 4, esp_y0 + esp32_pcb_w - 2, esp_z0 + 6],
                       [pca_x + pca_pcb_l + 2, bay_y + inner_w / 2 + 4, box_h - 8],
                       [pcb_x0 + pca_pcb_l - 3, pcb_y0 + 14, pcb_z0 + 6]], 3);
