// =====================================================================
// keel_fitcheck_jct.scad — junction-tray FIT CHECK plate for the keel.
//
// Crops the junction-tray section out of the merged floor+shell (WAGO
// clip-fin rails, comb drop grooves, service windows, lid rabbet +
// clip sockets) and plates it with the coupler comb, the hinged latch
// bar (print orientation) and the junction lid (top-face down). One
// object, one filament — everything the WAGOs, Dupont extensions,
// hinge pin and lid clips need proving before the body prints.
//
// The TPU egress bushing is NOT on this plate (different material):
// print keel_base.scad part="grommet" separately in TPU 95A.
//
//   openscad -o plate.stl -D 'fpart="plate"' keel_fitcheck_jct.scad
// =====================================================================

include <keel_base.scad>
part  = "none";     // suppress keel_base's own emission
fpart = "plate";

module jct_crop() {
    intersection() {
        union() { keel_floor(); keel_shell(); }
        translate([-58, -41, -0.1]) cube([56, 82, H + 0.2]);
    }
}

if (fpart == "crop") jct_crop();
if (fpart == "plate") {
    translate([68, 51, 0]) jct_crop();
    translate([110, 45, 0]) coupler_comb();
    // latch bar: flipped so its top plate is on the bed, arms/pads up
    translate([110, 130, 14.6]) rotate([180, 0, 0]) comb_bar();
    // junction lid: top face down, clips up (inlay-style, like the
    // spine lids)
    translate([220, 55, lid_t]) rotate([180, 0, 0]) keel_lid_junction();
}
