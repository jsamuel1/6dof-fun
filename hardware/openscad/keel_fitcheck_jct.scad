// =====================================================================
// keel_fitcheck_jct.scad — junction-tray FIT CHECK plate for the keel.
//
// Crops the junction-tray section out of the merged floor+shell (hub
// pair pockets, comb drop grooves, service windows, lid rabbet + clip
// sockets) and plates it with the coupler comb, the hinged latch bar
// (print orientation) and the junction lid (top-face down). One
// object, one filament — everything the WAGOs (station corridors +
// wire-tail clearance!), Dupont extensions, hinge pin and lid clips
// need proving before the body prints.
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
        translate([-80, -52, -0.1]) cube([74.5, 104, H + 0.2]);
    }
}

// Each part exports SEPARATELY (own object in the 3mf, so per-object
// print settings work); positions here are just the initial layout.
if (fpart == "crop") translate([85, 55, 0]) jct_crop();
// junction lid: top face down, clips up (inlay-style, like the
// spine lids)
if (fpart == "lid") translate([165, 60, lid_t]) rotate([180, 0, 0]) keel_lid_junction();
if (fpart == "comb") translate([200, 50, 0]) coupler_comb();
// latch bar: flipped so its top plate is on the bed, ears/pads up
if (fpart == "bar") translate([200, 150, 14.6]) rotate([180, 0, 0]) comb_bar();
if (fpart == "plate") {                       // debug view: everything
    translate([85, 55, 0]) jct_crop();
    translate([165, 60, lid_t]) rotate([180, 0, 0]) keel_lid_junction();
    translate([200, 50, 0]) coupler_comb();
    translate([200, 150, 14.6]) rotate([180, 0, 0]) comb_bar();
}
