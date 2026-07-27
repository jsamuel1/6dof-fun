// =====================================================================
// keel_test_plates.scad — 5-minute measurement coupons for the keel's
// two blocking MEASURE-MEs:
//
//   "feet" — arm bracket-foot screw pattern (drives arm_screw_dx/dz on
//            the adapter plate). Assumed 48 x 60 (M3).
//   "buck" — buck converter mounting holes (drives buck_hole_dl/dw).
//            Assumed 57 x 42 (M3).
//   "both" — the two coupons side by side on one tiny plate (default).
//
// Each hole is a CROSS SLOT (±4 mm travel in both axes): set the coupon
// on the real part, drop screws through into the real holes, and read
// each screw's offset from the cross centre with a ruler — that offset
// IS the correction to the assumed spacing. Embossed labels give the
// assumed pattern; the arrow marks +x (keel fore) so orientation gets
// recorded with the measurement.
//
// Print: 1.6 mm, 2 perimeters, 10% infill, any material — minutes.
// =====================================================================

include <common_params.scad>

part = "both";

t = 1.6;             // coupon thickness
slot_travel = 8;     // total cross-slot travel (±4)
slot_w = 3.4;        // M3 clearance

module cross_slot() {
    vent_slot(slot_travel + slot_w, slot_w, t);
    rotate([0, 0, 90]) vent_slot(slot_travel + slot_w, slot_w, t);
}

module label(txt, size = 5)
    linear_extrude(t + 0.6) text(txt, size = size, halign = "center",
                                 valign = "center");

module arrow() {
    linear_extrude(t + 0.6) polygon([[4, 0], [-2, 3], [-2, -3]]);
}

// picture-frame coupon: outer rounded plate, hollow centre (fast print),
// cross-slots at the 4 corners of the assumed dx x dz pattern
module coupon(dx, dz, tag) {
    difference() {
        rounded_plate(dx + 22, dz + 22, t);
        translate([11 + dx / 2, 11 + dz / 2, 0]) {
            translate([0, 0, -0.1])
                linear_extrude(t + 0.2)
                    rrect_test(dx - 18, dz - 18);
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx * dx / 2, sy * dz / 2, 0]) cross_slot();
        }
    }
    // embossed pattern label + fore arrow on the frame
    translate([11 + dx / 2, 11 + dz / 2, 0]) {
        translate([0, -dz / 2, 0]) label(tag, 4.5);
        translate([0, dz / 2, 0]) arrow();
    }
}
module rrect_test(l, w) offset(r = 4) square([l - 8, w - 8], center = true);

module feet_coupon() coupon(48, 60, "FEET 48x60");
module buck_coupon() coupon(57, 42, "BUCK 57x42");

if (part == "feet") feet_coupon();
if (part == "buck") buck_coupon();
if (part == "both") {
    feet_coupon();
    translate([0, 88, 0]) buck_coupon();
}
