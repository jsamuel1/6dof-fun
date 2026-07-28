// =====================================================================
// keel_base.scad — Concept A "KEEL" v3.7: the arm's integrated base.
// The space directly below the arm is the electronics bay: both logic
// boards ride SLIDE-OUT DRAWERS exiting the front wall; the power chain
// (buck + HUSB238 + ORing pair) lives in the aft chamber; the WAGO
// junction sits on the centreline between them. Edge clamps mount
// through slots in the body inboard of the transom — no screw ears.
// Design rationale + honest review: hardware/keel-concept/.
//
// v3.6 coupler comb is a real Dupont CONNECTOR RACK (six channels,
// captive PCA-side plugs, hinged latch bar); v3.7 harness egress is a
// plain bore + TPU bushing through the junction lid at x = -17.
// LATCH DECISION (was open in the handoff): PINNED HINGE — the bar
// swings open on a Ø3.4 pin through knuckles aft of the end stop and
// can never be mislaid; closure is the fore hook over the catch ledge.
// One Ø3.4 x ~60 pin in the BOM (a nail or rod stock works).
//
// Drop this next to common_params.scad in hardware/openscad/.
//
// Parts (-D 'part="..."'):
//   "floor" | "shell" | "body" (floor+shell merged: single-print
//   fallback — the click-off base is the primary architecture)
//   | "lid_pwr" | "lid_jct" | "cap" | "drawer" (both boards, v3.8)
//   | "sled_buck" | "comb" | "comb_bar" | "grommet" (TPU!) | "adapter"
//   | "clamp_spine" | "clamp_jaw" | "clamp" (assembled ref) | "clamp_ext"
//   | "clamp_knob" | "all"
//
// Print flat, no supports. PLA fit check, then PETG (grommet/feet: TPU).
// =====================================================================

include <common_params.scad>

part = "all";

// ---------------------------------------------------------------------
// Height budget — driven by the ESP32 standing ON ITS SIDE in its drawer
// (pins inboard): 2.5 floor + 1.6 sled + 28.9 board width + 2.6 air +
// 2.4 deck = 38. (v3.1: was 36 with 0.6 mm air — no allowance for
// first-layer squish or PCB edge tolerance. Review §1.)
// Sleds bear directly ON the floor between low side guides; drawers live
// under a fixed vented deck the arm feet sit on.
// ---------------------------------------------------------------------
H        = 38;
floor_h  = 2.5;
lid_t    = 2.4;
deck_t   = 2.4;

// --- plan: slim delta, 208 x 124 ---------------------------------------
front_x   = 88;
rear_x    = -120;
half_w    = 62;

// --- drawer (under the arm) ----------------------------------------------
// v3.8: ONE full-width drawer carries BOTH boards, pulling out
// together — the ESP32<->PCA9685 interconnects (I2C, VIN) travel with
// the drawer, so sliding it can never pull those wires out. The ESP32
// stands on its side in a cradle (pins inboard, USB-C to the face) in
// its lane; the PCA9685 lies flat, servo row outboard, in its lane; a
// KEEP-CLEAR centre lane (|y| < 5) and the two boss lanes (y = +-30
// above plug height) let the deck rib and M4 columns pass overhead.
drw_z = 27;   drw_w = 34;   drw_l = 94;   // legacy refs (windows etc.)
drw_w_all = 88;                            // the single bay's width
esp_lane = -16;  pca_lane = 22;            // board lane centrelines
sled_t = 1.6;
sled_l = drw_l - 22;   // sled stops short of the tunnel rear: service-loop space
guide_w = 2.5;  guide_h = 5;   // floor-level side guides the sled runs between
detent_d = 1.6;                // guide bump; sled edge scallop d = 2.2 (v3.1)
esp_hole_dl = 46.5;  esp_hole_dw = 23.3;   // used by the side cradle
pca_hole_dl = 56.0;  pca_hole_dw = 19.0;
pca_seat_h  = 2.4;

// --- aft power chamber ----------------------------------------------------
// Buck (65 x 48, holes 57 x 42 *** MEASURE ME ***) on a slide-in sled;
// HUSB238 STEMMA QT (~22 x 18) + Pololu ORing pair (~20 x 15) on a shelf.
ch_x = -85;  ch_l = 66;  ch_w = 52;
buck_hole_dl = 57;  buck_hole_dw = 42;

// --- ballast lobes ---------------------------------------------------------
lobe_x = -76;  lobe_z = 40;  lobe_l = 30;  lobe_w = 14;

// --- servo power junction tray (WAGOs ride the comb), CENTRELINE -----------
// Each polarity = two bridged 5-way 221-415s in a comb-mounted station:
// 10 entries = feed + jumper + 6 servos + 2 spare. Every clamp opens
// and re-wires with just the tray lid off.
jt_x = -30;  jt_l = 40;  jt_w = 86;               // tray opening at z = 0
wago_l = 18.6;  wago_w = 30;  wago_h = 8.3;       // 221-415 body
// v3.9 servo wiring strategy: the WAGOs LIVE ON THE COMB. Servo + and
// - wires clip DIRECTLY into the levers (a WAGO grips stripped wire
// better than any connector), and only the SIGNALS couple through
// Dupont: 3x 2-pin plugs, two servos per plug. The comb is the whole
// lift-out junction: two flat WAGO stations (2x 221-415 each, levers
// up, entries inboard) on its wings, a slim 3-channel signal rack
// between them, captive-male end stop + hinged latch bar. Lift the
// comb and the ENTIRE junction comes out in one piece, wires attached.
// v3.9b THREE-TIER POWER: the supplies' egress terminates on a FIXED
// baseplate WAGO pair (the hub, under the comb); one jumper pair feeds
// the comb's servo stations, another feeds a DRAWER-mounted pair that
// powers the boards (ESP32 VIN, PCA V+ logic). Each removable layer
// disconnects at its own jumpers: the comb lifts after unclipping two
// wires, the drawer pulls after unclipping two — the supply wiring is
// never touched. 8x 221-415 total (4 comb, 2 base, 2 drawer).
comb_y      = 16;    // plate underside height (base pair lives below)
comb_pitch  = 8;     // signal channel pitch (3 channels, 4 dividers)
comb_ch_w   = 6.6;   // clear width: 2-pin Dupont ~6.2 wide (per spec)
comb_div_h  = 9;     // divider height above the plate
// 2-pin 2.54 Dupont: male ~9 x 6.2, female ~14.5 x 6.4 (per spec).
// FIT-CHECK item: WAGO entries are inboard-horizontal — confirm wire
// access over the centre rack on the printed tray.

// --- arm adapter plate (SEPARATE PRINT) --------------------------------------
// The two stock L-bracket feet bolt to this plate; the plate screws to the
// body with four M4s inserted FROM BELOW through deck bosses (reachable
// via the drawer tunnels) into M4 heat-sets in the adapter. Fit-tests and
// future arms swap the adapter, not the 13-hour body print.
adp_l = 96;  adp_w = 86;  adp_t = 4;  adp_x = 40;
adp_screw_dx = [16, 64];  adp_screw_dz = [-30, 30];   // body<->adapter, M4
arm_screw_dx = [16, 64];    // bracket feet -> adapter *** MEASURE ME ***
arm_screw_dz = [-30, 30];

// --- transom I/O -------------------------------------------------------------
jack_z   = floor_h + 14;   jack_d = 11.2;   jack_y = -14;
usbc_w   = 10.5;  usbc_h = 5.0;             // *** MEASURE ME *** panel exts
usbc_pd_y = 2;    usbc_srv_y = 17;

// --- harness egress (v3.7): plain bore + TPU bushing through the lid --
// The 6 x 3-wire harness rises STRAIGHT UP through the junction lid at
// x = -17: aft of the adapter plate's edge (x = -8) and the arm's aft
// bracket foot (x = -6), so the bore exits into open air, directly over
// the comb's fore lead-outs — no sideways load on the connectors. The
// v3.5 U-notch + shell rim relief are deleted; lid removal is: unplug
// the six comb joints, lift the lid clear.
egress_x     = -17;
lid_bore_d   = 10.8;        // bore in the lid (r 5.4)
grom_bore_d  = 9.0;         // harness bore (6 x 3-wire ~ 8.5 bundled)
grom_waist_d = 11.2;        // bushing waist: 0.4 press in the lid bore
grom_flange_d = 16;         // flanges above + below the lid (slit ring:
                            // squeeze to install, harness side-loads in)

// --- lid snap clips -----------------------------------------------------------
clip_w = 6;  clip_t = 1.6;  clip_drop = 4.5;  clip_nub = 0.8;

// --- desk edge clamp: THROUGH-BODY mount, at the WIDE (arm) edge -----------
// The clamps live at the wide end where the arm works — opposite the
// connector nose — so the clamp force counters the tipping moment where it
// acts. v3.2 orientation (it was reversed): the keel's clamp corners
// OVERHANG the bench edge ~20 mm (front feet sit inboard, still on the
// bench); the T-head bears in the deck recess, the spine drops through
// the slot PAST the edge, and the jaw + M6 thumbscrew reach back INBOARD
// under the benchtop — clamping the keel down onto the bench it sits on.
// No tools, no ears. Stowed: folded flat on the deck, arms inboard,
// clipped under printed stow posts + lips.
slot_x = 76;  slot_z = 56;  slot_l = 21;  slot_w = 11;   // through-slots
clamp_throat   = 52;      // clears a 2" (50.8) bench top
clamp_ext_add  = 50;      // extension part: tops up to ~4"
clamp_w        = 20;
clamp_spine_t  = 8;
clamp_jaw_l    = 34;
clamp_screw_d  = 6;       // M6 through a heat-set nut in the jaw
clamp_pad_d    = 14;      // TPU pressure pad

// --- feet ------------------------------------------------------------------
feet = [[-106, -26], [-106, 26], [56, -50], [56, 50]];  // front pair inboard of the bench edge when clamped (v3.2)
foot_d = 22;  foot_h = 4;

// =====================================================================
module plan() {
    hull() for (sy = [-1, 1]) {
        translate([rear_x + 8,  sy * 34])           circle(r = 8);
        translate([-100,        sy * 42])           circle(r = 8);
        translate([-40,         sy * (half_w - 8)]) circle(r = 8);
        translate([front_x - 14, sy * (half_w - 14)]) circle(r = 14);
    }
}
module rrect(l, w, r) offset(r = r) square([l - 2 * r, w - 2 * r], center = true);
module ch_plan()   translate([ch_x, 0]) rrect(ch_l, ch_w, 6);
module jt_plan()   translate([jt_x, 0]) rrect(jt_l, jt_w, 5);
module drw_plan() translate([42, 0]) rrect(drw_l, drw_w_all, 4);
module lobe_plan(s) translate([lobe_x, s * lobe_z]) rrect(lobe_l, lobe_w, 5);
module slot_plan(s) translate([slot_x, s * slot_z]) rrect(slot_l, slot_w, 4);

// --- click-off base ---------------------------------------------------------
// The floor is a separate part: a perimeter snap lip rides up inside the
// shell wall, then 4 countersunk M3s lock it FROM BELOW into shell-wall
// boss pads (v3.2 — no inside access needed; the TPU feet keep the heads
// off the bench). The TRANSOM POWER WALL rides the base too: jack + both
// USB-C extensions wire to boards on the base, so the whole power end
// comes away with the floor. Pop the base and all wiring is open.
base_lip_h = 3;
base_screws = [[-70, -51.8], [-70, 51.8], [40, -57.8], [40, 57.8]];  // boss centres

module keel_floor() {
    difference() {
        linear_extrude(floor_h) plan();
        for (s = [-1, 1], i = [0 : 3])          // drawer tunnel vents
            translate([4 + i * 22, s * drw_z, 0]) vent_slot(16, vent_slot_w, floor_h);
        for (i = [-1 : 1])                      // chamber vents
            translate([ch_x + 2, i * 15, 0]) vent_slot(40, vent_slot_w, floor_h);
        for (s = [-1, 1]) translate([0, 0, -0.1])
            linear_extrude(floor_h + 0.2) slot_plan(s);   // clamp through-slots
        for (f = feet) translate([f[0], f[1], -0.1]) cylinder(h = 1.2, d = foot_d + 0.6);
        // base screws: countersunk M3 clearance UP through the floor into
        // the shell-wall bosses (fasten from below, base on the bench)
        for (p = base_screws) translate([p[0], p[1], -0.1]) {
            cylinder(h = floor_h + 0.2, d = m3_free_d);
            cylinder(h = 1.7, d1 = 6.4, d2 = m3_free_d);
        }
        // (v3.1: floor raceways DELETED — 1.5 mm was useless for a 16 AWG
        //  pair and a 4 mm channel can't live in a 2.5 mm floor. Wires now
        //  run in the tunnel/tray corners through the wall pass-throughs
        //  at floor_h + 2; the click-off base opens all of it anyway.)
    }
    // perimeter snap lip, inset one wall thickness; notched around the
    // shell's base-screw boss pads
    translate([0, 0, floor_h]) linear_extrude(base_lip_h)
        difference() {
            offset(delta = -wall_t - 0.15) plan();
            offset(delta = -wall_t - 2.5) plan();
            for (p = base_screws)
                translate([p[0], p[1]]) square([16, 22], center = true);
            // v3.3: lip breaks at the drawer mouth so the face passes
            translate([85, 0]) square([12, drw_w_all + 2], center = true);
        }
    // v3.2: TRANSOM POWER WALL — part of the base. Rises into the shell's
    // rear notch; the chamber lid caps the joint at the top.
    difference() {
        translate([rear_x, -29.7, floor_h]) cube([2, 59.4, H - floor_h - lid_t]);
        translate([rear_x - 0.1, jack_y, jack_z]) rotate([0, 90, 0])
            cylinder(h = 10, d = jack_d);
        for (y = [usbc_pd_y, usbc_srv_y])
            translate([rear_x - 0.1, y - usbc_w / 2, jack_z - usbc_h / 2])
                cube([wall_t + 4, usbc_w, usbc_h]);
    }
    // HUSB238 + ORing shelf, fused to the transom wall (v3.2: it floated
    // unattached in the shell before, and its boards wire to the transom)
    translate([rear_x + 1.9, -22, floor_h]) cube([10, 44, 18]);
    // v3.1: the old "ledge rails" floated 2.6 mm above the floor with
    // nothing under them (unprintable) and lifted the sled out of the
    // height budget. Sleds now bear directly ON the floor between solid
    // side guides; guides ride the base so drawers come away with it.
    for (e = [-1, 1])
        translate([9, e * (drw_w_all / 2 - 2.5) - guide_w / 2, floor_h])
            cube([drw_l - 16, guide_w, guide_h]);
    // drawer detents: a bump on each guide's inner face snaps into a
    // scallop in the sled edge when the drawer is home (review §2)
    for (e = [-1, 1])
        translate([76, e * (drw_w_all / 2 - 2.5 - guide_w / 2), floor_h + 2])
            sphere(d = detent_d, $fn = 16);
    // v3.9b BASEPLATE WAGO PAIR — the supplies' 6V egress hub. Buck
    // feed in; jumper pairs out to the comb's servo stations and the
    // drawer's board-power pair. Lives under the comb: lift the comb
    // (2 jumper wires) for lever access. Entries face FORE.
    for (sy = [-1, 1]) difference() {
        translate([-46, sy * 17 - wago_w / 2 - 1.8, floor_h])
            cube([wago_l + 3.6, wago_w + 3.6, 4]);
        translate([-44.4, sy * 17 - wago_w / 2 - 0.2, floor_h - 0.1])
            cube([wago_l + 0.4, wago_w + 0.4, 4.2]);
        translate([-27, sy * 17 - 4, floor_h - 0.1]) cube([4, 8, 4.2]);
    }
}

// clip-socket cutter: pockets in the shell wall the lid clips bite into
// (v3.1: the module header was missing — the file didn't parse)
module snap_sockets(cx, cz, dx, dz) {
    for (sx = [-1, 1], sz = [-1, 1])
        translate([cx + sx * dx - clip_w / 2 - 0.3, cz + sz * dz - clip_t - 0.3,
                   H - lid_t - clip_drop - 0.3])
            cube([clip_w + 0.6, clip_t + 0.6, clip_drop + 0.4]);
}

module keel_shell() {
    difference() {
        linear_extrude(H) plan();
        // chamber + junction: open to the top (lidded)
        translate([0, 0, floor_h]) linear_extrude(H) { ch_plan(); jt_plan(); }
        // ballast lobes
        translate([0, 0, floor_h]) linear_extrude(H)
            for (s = [-1, 1]) lobe_plan(s);
        // drawer bay (v3.8: ONE full-width tunnel), open to the FRONT,
        // roofed by the deck
        translate([0, 0, floor_h]) linear_extrude(H - floor_h - deck_t) drw_plan();
        // front wall opening — open at the BOTTOM (shell starts at
        // floor_h): no sill, the drawer rides the base out (v3.2)
        translate([front_x - wall_t - 2, -drw_w_all / 2, floor_h])
            cube([wall_t + 6, drw_w_all, H - floor_h - deck_t]);
        // clamp through-slots + T-head recess on the deck
        for (s = [-1, 1]) {
            translate([0, 0, -0.1]) linear_extrude(H + 0.2) slot_plan(s);
            translate([slot_x, s * slot_z, H - 5])
                linear_extrude(5.1) rrect(slot_l + 9, slot_w + 15, 4);
        }
        // lid rabbets + clip sockets
        translate([0, 0, H - lid_t]) linear_extrude(lid_t + 0.1) {
            translate([ch_x, 0]) rrect(ch_l + 8, ch_w + 8, 8);
            translate([jt_x, 0]) rrect(jt_l + 6, jt_w + 6, 6);
            for (s = [-1, 1]) translate([lobe_x, s * lobe_z]) rrect(lobe_l + 6, lobe_w + 6, 7);
        }
        snap_sockets(ch_x, 0, ch_l / 2 - 8, ch_w / 2 + 0.5);
        snap_sockets(jt_x, 0, 16, jt_w / 2 + 0.5);
        // wire pass-throughs. Connector ENDS thread through these
        // end-first (runs lie open from below with the base popped),
        // so each port is sized for the largest END on its route, not
        // just the wires:
        // chamber->junction: buck 6V pair AND the ESP32's USB-C
        // service extension pass here - a USB-C plug is ~10.5 x 6.5
        translate([ch_x + ch_l / 2 - 0.1, -6.5, floor_h + 2]) cube([8, 13, 10]);
        // junction->ESP tunnel: VIN + I2C + that same USB-C extension
        // continuing to the drawer face - window, not a wire hole
        translate([jt_x + jt_l / 2 - 0.1, -(drw_z - 14) - 8, floor_h + 2])
            cube([10, 14, 12]);
        // PCA side (v3.1): widened to a service WINDOW — the six pigtails
        // to the coupler comb and the power pair route through here, and
        // a finger reaches the drawer's leads with the tray lid off
        translate([jt_x + jt_l / 2 - 0.1, 12, floor_h + 2])
            cube([10, 19, 14]);
        // coupler-comb drop grooves in the tray z-walls (v3.6): the
        // comb's side tongues (30 x 3 x 2.6) slide down these to rest
        // at comb_y — groove is tongue + fit slop, open to the top
        for (sz = [-1, 1])
            translate([jt_x - 15.5, sz * (jt_w / 2 + 1.6) - 1.8, comb_y - 0.2])
                cube([31, 3.6, H - comb_y + 0.2]);
        // transom notch (v3.2): the base's power wall fills this — the
        // jack + USB-C cutouts moved to the floor part's transom wall
        translate([rear_x - 0.1, -30, floor_h - 0.1]) cube([2.2, 60, H + 0.2]);
        // base-screw pilots up into the wall-bottom boss pads
        for (p = base_screws)
            translate([p[0], p[1], floor_h - 0.1]) cylinder(h = 8.1, d = m3_pilot_d);
        // (v3.7: the v3.5 rim U-relief is gone — egress is a plain bore
        //  in the junction lid at egress_x, see keel_lid_junction)
        // adapter screw bores through the deck: M4 from below, heads
        // recessed into the tunnel roofs / centreline spine
        for (x = adp_screw_dx, z = adp_screw_dz) {
            translate([x, z, H - deck_t - 6.1]) cylinder(h = deck_t + 6.2, d = 4.4);
            translate([x, z, H - deck_t - 6.1]) cylinder(h = 4, d = 8.4); // head recess
        }
    }
    // (drawer ledge rails + junction rails moved to keel_floor — the
    //  click-off base carries drawers, PCBs and WAGO rails with it)
    // v3.8: with the tunnel centre spine gone, a centreline rib
    // stiffens the deck along the keep-clear lane (drawer contents stay
    // out of |y| < 5 at full height; it clears the PCA plug tops by 4)
    translate([-4, -4, H - deck_t - 6]) cube([front_x - wall_t - 4 + 4, 8, 6]);
    // v3.1: M4 boss columns under the deck at the adapter screw points.
    // The head recess above finally has plastic around it, and the four
    // columns stiffen the 2.4 mm deck at the arm-foot rows (review §5 —
    // a full-width 8 mm cross-rib would hit the upright ESP32; these
    // clear the PCA plug tops by ~8 mm and sit outboard of the ESP32
    // board plane).
    for (x = adp_screw_dx, z = adp_screw_dz)
        translate([x, z, H - deck_t - 6]) difference() {
            cylinder(h = 6, d = 10);
            translate([0, 0, -0.1]) cylinder(h = 6.2, d = 4.4);
            translate([0, 0, -0.1]) cylinder(h = 4.1, d = 8.4);
        }
    // v3.2 base-screw boss pads: thicken the wall inboard so the M3
    // pilots keep boss_wall_min (the base lip is notched around them)
    for (p = base_screws)
        translate([p[0] - 6, p[1] - (p[1] > 0 ? 5.5 : 3.5), floor_h])
            cube([12, 9, 8]);
    // clamp stow (v3.2): clamps fold FLAT on the deck, arms inboard,
    // T-heads at the flank edges; these posts + lips clip over the spines
    for (s = [-1, 1], hx = [20, 64]) {
        translate([hx - 3, s * 57 - 1.5, H]) cube([6, 3, 20]);
        translate([hx - 3, (s > 0 ? 50 : -57), H + 17]) cube([6, 7, 3]);
    }
}

// --- arm adapter plate ---------------------------------------------------
module arm_adapter() {
    difference() {
        linear_extrude(adp_t) translate([adp_x, 0]) rrect(adp_l, adp_w, 6);
        // M4 heat-set pockets (underside) for the body screws
        for (x = adp_screw_dx, z = adp_screw_dz)
            translate([x, z, -0.1]) cylinder(h = adp_t - 1.2, d = 5.6);
        // bracket-foot M3 clearance *** MEASURE ME against the real feet ***
        for (x = arm_screw_dx, z = arm_screw_dz)
            translate([x, z, -0.1]) cylinder(h = adp_t + 0.2, d = m3_free_d);
    }
}

// --- lids --------------------------------------------------------------
module lid_clips(dx, dz) {
    for (sx = [-1, 1], sz = [-1, 1])
        translate([sx * dx - clip_w / 2, sz * dz - clip_t, -clip_drop]) {
            cube([clip_w, clip_t, clip_drop]);
            translate([0, -clip_nub, 0]) cube([clip_w, clip_nub, 1.4]);
        }
}
module keel_lid_power() {
    difference() {
        linear_extrude(lid_t) translate([ch_x, 0]) rrect(ch_l + 8, ch_w + 8, 8);
        for (c = [-3 : 3], r = [-2 : 2])
            translate([ch_x + c * 9, r * 10.5, -0.1]) cylinder(h = lid_t + 0.2, d = 3.6);
    }
    translate([ch_x, 0]) lid_clips(ch_l / 2 - 8, ch_w / 2 - 1);
}
module keel_lid_junction(motif = true) {
    difference() {
        linear_extrude(lid_t) translate([jt_x, 0]) rrect(jt_l + 6, jt_w + 6, 6);
        for (r = [-4 : 4])
            translate([jt_x - 15, r * 7, -0.1]) cylinder(h = lid_t + 0.2, d = 3.2);
        // v3.7: the +- motif window moved to the tray centreline to
        // clear the egress bore
        if (motif)
            translate([jt_x, 0, -0.1]) linear_extrude(lid_t + 0.2) rrect(8, 54, 2);
        // v3.7 harness egress: plain bore, TPU bushing pressed in;
        // rises directly over the comb's fore lead-outs
        translate([egress_x, 0, -0.1]) cylinder(h = lid_t + 0.2, d = lid_bore_d);
    }
    translate([jt_x, 0]) lid_clips(16, jt_w / 2 - 1);
}
module keel_lid_junction_motif()
    translate([jt_x, 0, 0]) linear_extrude(lid_t) rrect(7.4, 53.4, 2);
module keel_cap(z) {
    difference() {
        linear_extrude(lid_t) translate([lobe_x, z]) rrect(lobe_l + 6, lobe_w + 6, 7);
        translate([lobe_x, z, 0]) vent_slot(14, 3, lid_t);
    }
}

// --- drawer (v3.8: ONE drawer, both boards) --------------------------------
// Centred on y = 0. The sled rides the floor between the edge guides;
// one red face closes the full-width mouth with a centre finger pull.
// ESP32 lane: vertical cradle at esp_lane (board on its side, pins
// inboard, USB-C to the face). PCA lane: flat standoffs at pca_lane,
// servo row outboard. Keep-clear: |y| < 5 (deck rib) and the y = +-30
// boss lanes above plug height.
module drawer_boards() {
    difference() {
        union() {
            translate([0, -(drw_w_all - 6) / 2, 0])
                cube([sled_l, drw_w_all - 6, sled_t]);           // sled
            translate([sled_l, -drw_w_all / 2 - 1, 0])
                cube([2.4, drw_w_all + 2, H - floor_h - deck_t - 2]);  // face
            translate([sled_l + 2, -8, 10]) cube([4, 16, 4]);    // pull
            // ESP32 vertical cradle: two pockets grip the PCB edges
            for (x = [10, 62])
                translate([x, esp_lane - 4.5, sled_t]) cube([6, 4, 26]);
            translate([8, esp_lane - 6.5, sled_t]) cube([62, 2, 30]);  // back wall
        }
        // detent scallops: mate the guide bumps when the drawer is home
        for (y = [-(drw_w_all - 6) / 2 + 3, (drw_w_all - 6) / 2 - 3])
            translate([sled_l - 3, y, -0.1]) cylinder(h = sled_t + 0.2, d = 2.2);
        // face window for the USB-C panel extension at the ESP32 lane —
        // flange size drives the final cutout *** MEASURE ME ***
        translate([sled_l - 0.1, esp_lane - 5.25, sled_t + 12])
            cube([2.7, 10.5, 5.5]);
    }
    // v3.9b DRAWER WAGO PAIR: board power rides the drawer — ESP32
    // VIN and PCA V+ clip here; the jumper pair from the base pair is
    // the drawer's only power umbilical (unclip it to pull the drawer
    // fully out). Sits in the middle band, well under the deck rib.
    for (sx = [-1, 1]) difference() {
        translate([sled_l / 2 + sx * 17 - wago_w / 2 - 1.8, -13.2, sled_t])
            cube([wago_w + 3.6, wago_l + 3.6, 4]);
        translate([sled_l / 2 + sx * 17 - wago_w / 2 - 0.2, -11.6, sled_t - 0.1])
            cube([wago_w + 0.4, wago_l + 0.4, 4.2]);
        translate([sled_l / 2 + sx * 17 - 4, -14, sled_t - 0.1])
            cube([8, 4, 4.2]);
    }
    // PCA9685 flat standoffs, servo row outboard (+y)
    for (px = [-1, 1], pz = [-1, 1])
        translate([sled_l / 2 + px * pca_hole_dl / 2,
                   pca_lane + pz * pca_hole_dw / 2, sled_t])
            standoff(pca_seat_h, m25_pilot_d);
}
module sled_buck() {
    cube([ch_l - 10, ch_w - 8, sled_t]);
    for (px = [-1, 1], pz = [-1, 1])
        translate([(ch_l - 10) / 2 + px * buck_hole_dl / 2,
                   (ch_w - 8) / 2 + pz * buck_hole_dw / 2, sled_t])
            standoff(4, m25_pilot_d);
}

// --- servo coupler comb (v3.6): Dupont CONNECTOR RACK ----------------------
// Separate flat print (channel side up). Drops into the tray-wall
// grooves on its side tongues, resting at comb_y ABOVE the WAGO lanes.
// Local frame: origin = tray centre (place with translate([jt_x,0,comb_y]));
// +x fore. Aft->fore per channel: end stop | male PCA pigtail plug
// (captive against the stop) | female arm plug | out to the harness.
comb_plate_l = 38;  comb_plate_w = 84;  comb_plate_t = 3;
module coupler_comb() {
    difference() {
        union() {
            translate([-comb_plate_l / 2, -comb_plate_w / 2, 0])
                cube([comb_plate_l, comb_plate_w, comb_plate_t]);
            // side tongues ride the tray-wall grooves
            for (sy = [-1, 1])
                translate([-15, sy * comb_plate_w / 2 - (sy > 0 ? 0 : 3), 0])
                    cube([30, 3 + comb_plate_w / 2 - 42, 2.6]);
            // WAGO stations on the wings (v3.9): two 221-415 pockets
            // per polarity, flat, levers up, entries INBOARD; low
            // walls + clip nubs — any one clamp pops out alone
            for (sy = [-1, 1], wx = [-1, 1]) {
                px = wx * (wago_l / 2 + 0.6);
                py = sy * (12.4 + wago_w / 2);
                difference() {
                    translate([px - wago_l / 2 - 1.8, py - wago_w / 2 - 1.8,
                               comb_plate_t])
                        cube([wago_l + 3.6, wago_w + 3.6, 4]);
                    translate([px - wago_l / 2 - 0.2, py - wago_w / 2 - 0.2,
                               comb_plate_t - 0.1])
                        cube([wago_l + 0.4, wago_w + 0.4, 4.2]);
                    translate([px - wago_l / 2 - 2,
                               py - sy * (wago_w / 2 + 2) - 2,
                               comb_plate_t - 0.1])
                        cube([wago_l + 4, 4, 4.2]);      // entry face open
                }
                for (nx = [-1, 1])                        // clip nubs
                    translate([px + nx * (wago_l / 2 + 0.1) - 0.6, py - 3,
                               comb_plate_t + 3.2])
                        cube([1.2, 6, 0.8]);
            }
            // aft end stop for the signal rack (captive male plugs)
            translate([-19, -13, comb_plate_t]) cube([3, 26, comb_div_h]);
            // hinge knuckles: lugs at y = -9 / 0 / +9, bored O3.4
            for (ky = [-9, 0, 9])
                translate([-25.2, ky - 2.5, 0])
                    cube([6.2, 5, comb_plate_t + 5]);
            // 4 dividers with flared fore lead-ins (3 signal channels,
            // one 2-pin Dupont pair per channel = two servos' signals)
            for (i = [0 : 3]) {
                dy = (i - 1.5) * comb_pitch;
                translate([-16, dy - 0.7, comb_plate_t])
                    cube([27, 1.4, comb_div_h]);
                hull() {
                    translate([11, dy - 0.7, comb_plate_t])
                        cube([0.1, 1.4, comb_div_h]);
                    translate([15.9, dy - 0.25, comb_plate_t])
                        cube([0.1, 0.5, comb_div_h]);
                }
            }
            // fore catch ledge for the latch bar hook
            translate([16.2, -5, comb_plate_t]) cube([2.5, 10, 2.5]);
            // index pips 1..3 on the fore lip
            for (i = [0 : 2], q = [0 : i])
                translate([17.2, (i - 1) * comb_pitch - i * 1.2 + q * 2.4 - 0.5,
                           comb_plate_t])
                    cube([1.4, 1, 1.4]);
            // finger lifts at the fore corners
            for (sy = [-1, 1])
                translate([13, sy * (comb_plate_w / 2 - 3) - 3, comb_plate_t])
                    cube([6, 6, 9]);
        }
        // signal-lead drop-throughs, one per channel
        for (i = [0 : 2])
            translate([-9, (i - 1) * comb_pitch, 0])
                vent_slot(6, 3.6, comb_plate_t);
        // 6V feed slots up through the plate at each station's inboard end
        for (sy = [-1, 1])
            translate([-12, sy * 15, 0]) vent_slot(8, 4, comb_plate_t);
        // hinge pin bore through the knuckle lugs (O3.4 pin, ~40 long)
        translate([-22.2, -14, comb_plate_t + 1.5])
            rotate([-90, 0, 0]) cylinder(h = 28, d = 3.5);
    }
}

// --- comb latch bar (v3.9, PINNED HINGE over the 3 signal channels) ---------
// Modelled CLOSED. Rides the divider tops with a pad per channel; two
// hinge arms drop to the O3.4 pin through the comb's lugs; fore hook
// over the catch ledge. Print flat, pads-up (flip 180 about x).
module comb_bar() {
    bar_z = comb_plate_t + comb_div_h;
    translate([-17, -14, bar_z]) cube([34, 28, 2.6]);
    for (i = [0 : 2])
        translate([-15, (i - 1) * comb_pitch - 3.3, bar_z - 1.6])
            cube([30, 6.6, 1.6]);
    for (sy = [-1, 1]) difference() {
        union() {
            translate([-19.3, sy * 4.5 - 2, bar_z]) cube([2.5, 4, 2.6]);
            translate([-25.6, sy * 4.5 - 2, comb_plate_t - 0.5])
                cube([6.3, 4, comb_div_h + 3.1]);
        }
        translate([-22.2, sy * 4.5 - 2.1, comb_plate_t + 1.5])
            rotate([-90, 0, 0]) cylinder(h = 4.2, d = 3.7);
    }
    translate([16.2, -5, comb_plate_t + 1]) {
        translate([2.9, 0, 0]) cube([1.6, 10, 1.6 + comb_div_h]);
        cube([3, 10, 1.4]);
    }
}

// --- desk edge clamp (through-body) ---------------------------------------
// Prints on its side, no supports; layers run along the C. v3.4: TWO
// pieces, because neither the T-head (28 wide) nor the jaw (34 wide)
// fits through the 21 x 11 body slot. Install: drop the SPINE (with
// T-head) through the slot from above; bolt the JAW to its lower end
// with 2 x M4 + nuts -- the same splice joint clamp_ext uses (extension
// inserts between spine and jaw for benchtops up to ~4"). M6 heat-set
// nut in the jaw; octagonal printed knob, hand-tight only.
module clamp_spine(throat = clamp_throat) {
    translate([-36, -1, 0]) cube([28, 5, clamp_w + 4]);          // T-head
    difference() {
        // flat-blade spine 18 x 8: wide face in the load plane, passes the
        // 21 x 11 body slot
        translate([-31, -(throat + 4 + H) + 4, 2 + (clamp_w - 8) / 2])
            cube([18, throat + 4 + H + 1, 8]);
        // splice-hole LADDER, pairs every 14: the jaw bolts at whichever
        // rung puts it just under the benchtop, so one spine handles
        // benches from ~10 mm to the full 2" throat (M6 closes <=14 +
        // pad; clamp_ext extends past 2" to ~4")
        for (r = [0 : 5])
            translate([-31.1, -(throat + 4 + H) + 12 + r * 14, 2 + clamp_w / 2])
                rotate([0, 90, 0]) cylinder(h = 18.4, d = 4.4);
    }
}
module clamp_jaw() {
    difference() {
        union() {
            translate([-26, -8, 2]) cube([clamp_jaw_l, 8, clamp_w]);  // jaw
            for (x = [-35, -13])                                 // splice cheeks
                translate([x, 0, 2 + (clamp_w - 12) / 2]) cube([4, 26, 12]);
        }
        for (y = [4, 18])
            translate([-35.1, y, 2 + clamp_w / 2])
                rotate([0, 90, 0]) cylinder(h = 26.2, d = 4.4);  // M4 through
        translate([0, -8.1, clamp_w / 2 + 2])
            cylinder(h = 8.2, d = clamp_screw_d + 0.4);          // nut bore
    }
}
module desk_clamp(throat = clamp_throat) {   // assembled reference only
    clamp_spine(throat);
    translate([0, -(throat + 4 + H) + 8, 0]) clamp_jaw();
}
module desk_clamp_ext() {
    difference() {
        cube([clamp_spine_t, clamp_ext_add + 20, clamp_w]);
        for (y = [8, clamp_ext_add + 12], z = [5, clamp_w - 5])
            translate([-0.1, y, z]) rotate([0, 90, 0])
                cylinder(h = clamp_spine_t + 0.2, d = 4.4);
    }
}
module clamp_knob() {
    cylinder(h = 6, d = 22, $fn = 8);
    translate([0, 0, 6]) cylinder(h = 4, d = 12);
}

// --- TPU lid bushing (v3.7) --------------------------------------------------
// Slit ring pressed into the junction lid's egress bore: waist 0.4 over
// the bore, flanges sandwiching the 2.4 lid; the side slit lets the
// bushing squeeze in and the harness side-load through it. The harness
// never bears on a printed PETG edge.
module edge_bushing() {
    difference() {
        union() {
            cylinder(h = 1.6, d = grom_flange_d);            // lower flange
            translate([0, 0, 1.6]) cylinder(h = lid_t + 0.4, d = grom_waist_d);
            translate([0, 0, 1.6 + lid_t + 0.4])
                cylinder(h = 1.6, d = grom_flange_d);        // upper flange
        }
        translate([0, 0, -0.1]) cylinder(h = lid_t + 4, d = grom_bore_d);
        translate([-1.25, 0, -0.1]) cube([2.5, grom_flange_d / 2 + 1, lid_t + 4.2]);
    }
}

// =====================================================================
if (part == "floor")      keel_floor();
if (part == "shell")      keel_shell();
if (part == "body") { keel_floor(); keel_shell(); }   // single-print fallback:
    // forfeits the click-off base (transom/drawer/WAGO service access)
if (part == "comb_bar")   comb_bar();
if (part == "lid_pwr")    keel_lid_power();
if (part == "lid_jct")    keel_lid_junction();
if (part == "cap")        keel_cap(lobe_z);
if (part == "drawer")     drawer_boards();
if (part == "sled_buck")  sled_buck();
if (part == "comb")       coupler_comb();
if (part == "grommet")    edge_bushing();
if (part == "adapter")    arm_adapter();
if (part == "clamp_spine") rotate([0, -90, 0]) clamp_spine();
if (part == "clamp_jaw")   rotate([90, 0, 0]) clamp_jaw();
if (part == "clamp")       rotate([0, -90, 0]) desk_clamp();   // assembled ref
if (part == "clamp_ext")  rotate([0, -90, 0]) desk_clamp_ext();
if (part == "clamp_knob") clamp_knob();
if (part == "all") {
    keel_floor();
    keel_shell();
    translate([0, 0, H - lid_t]) {
        color("white") { keel_lid_power(); keel_lid_junction(); }
        color("red") {
            keel_lid_junction_motif();
            for (sz = [-1, 1]) keel_cap(sz * lobe_z);
        }
    }
    color("red") {
        translate([jt_x, 0, comb_y]) { coupler_comb(); comb_bar(); }
        translate([7, 0, floor_h]) drawer_boards();
        translate([ch_x - (ch_l - 10) / 2, -(ch_w - 8) / 2, floor_h]) sled_buck();
        translate([0, 0, H]) arm_adapter();
    }
    color("aqua") {
        for (f = feet) translate([f[0], f[1], -foot_h]) cylinder(h = foot_h, d = foot_d);
        translate([egress_x, 0, H - lid_t - 1.6]) edge_bushing();
    }
}
