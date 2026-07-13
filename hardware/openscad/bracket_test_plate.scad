// =====================================================================
// bracket_test_plate.scad
// Fit-check coupon for the arm-bracket screw interface.
//
// One thin plate with M3 hole PAIRS at several centre-to-centre
// spacings around the ruler-measured 18 mm. Print it (PLA, minutes),
// hold it against the metal bracket, and find the row where two M3
// screws drop through both plate and bracket freely. Set that value as
// bracket_hole_spacing_mm in common_params.scad, then print the mounts.
//
// Each row is labelled with its spacing. The hole diameter everywhere
// is bracket_screw_hole_d (M3 clearance, 3.4) — if screws bind even on
// the correct row, the clearance needs opening up, not the spacing.
// =====================================================================

include <common_params.scad>

// Spacings to test, mm centre-to-centre (measured value in the middle).
spacings = [16, 17, 18, 19, 20];

row_pitch  = 12;              // vertical distance between rows
plate_w    = 36;              // widest pair (20) + comfortable margin
plate_t    = 2.4;             // thin + rigid; prints fast
label_x    = 4;               // label column, left edge
text_depth = 0.6;             // deboss depth on the top face

plate_l = row_pitch * len(spacings) + 4;

difference() {
    rounded_plate(plate_w, plate_l, plate_t);

    for (i = [0 : len(spacings) - 1]) {
        y = row_pitch * (i + 0.5) + 2;

        // the pair of bracket screw holes, centred on the plate
        for (sx = [-1, 1])
            translate([plate_w / 2 + sx * spacings[i] / 2, y, -0.1])
                cylinder(h = plate_t + 0.2, d = bracket_screw_hole_d);

        // debossed spacing label on the top face
        translate([label_x, y, plate_t - text_depth])
            linear_extrude(text_depth + 0.1)
                text(str(spacings[i]), size = 5, halign = "left",
                     valign = "center", font = "Liberation Sans:style=Bold");
    }
}
