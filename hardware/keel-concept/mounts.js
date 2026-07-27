// mounts.js — parametric board-mount concepts for the 6DOF arm.
// Units: millimetres, y-up. The caller scales the returned group to metres.
//
// Dimensions traced from:
//   hardware/openscad/common_params.scad   (wall_t, floor_t, M3/M2.5, 18 mm row)
//   hardware/openscad/esp32_mount.scad     (52.0 x 28.9, holes 46.5 x 23.3)
//   hardware/openscad/pca9685_mount.scad   (62.5 x 25.4, holes 56 x 19)
//   hardware/CONNECTORS.md                 (ground truths — see notes inline)
import * as THREE from 'three';

/* ------------------------------------------------------------------ */
/* materials — the 4 filaments in hand + hardware/PCB context          */
/* ------------------------------------------------------------------ */
const std = (name, color, roughness, metalness = 0.05) =>
  new THREE.MeshStandardMaterial({ name, color, roughness, metalness });

export const M = {
  black:  std('petg_black',  0x24262b, 0.62),
  white:  std('petg_white',  0xe9e7e1, 0.55),
  red:    std('petg_red',    0xb0271f, 0.48),
  silver: std('abs_silver',  0xb7babe, 0.42, 0.32),
  aqua:   std('tpu_aqua',    0x27b3a4, 0.86, 0.02),
  steel:  std('steel',       0x9aa0a6, 0.34, 0.36),
  alu:    std('arm_alu',     0x2b2d32, 0.44, 0.28),
  pcbK:   std('pcb_black',   0x15171b, 0.48),
  pcbB:   std('pcb_blue',    0x1c3f6d, 0.48),
  hdr:    std('header_black',0x0e0e11, 0.72),
  pin:    std('pin_gold',    0xc7a12c, 0.34, 0.35),
  term:   std('terminal_green', 0x1f6b3a, 0.55),
  wago:   std('wago_orange', 0xdd7524, 0.5),
};

/* ------------------------------------------------------------------ */
/* geometry helpers                                                    */
/* ------------------------------------------------------------------ */
const mesh = (g, m, name) => { const o = new THREE.Mesh(g, m); o.name = name; return o; };
const box = (w, h, d, m, name) => mesh(new THREE.BoxGeometry(w, h, d), m, name);
const cyl = (r, h, m, name, seg = 32) => mesh(new THREE.CylinderGeometry(r, r, h, seg), m, name);

function circPath(x, y, r) {
  const p = new THREE.Path();
  p.absarc(x, y, r, 0, Math.PI * 2, true);
  return p;
}
function slotPath(x, y, l, w) {
  const r = w / 2, hx = Math.max(0, (l - w) / 2), p = new THREE.Path();
  p.moveTo(x - hx, y + r);
  p.lineTo(x + hx, y + r);
  p.absarc(x + hx, y, r, Math.PI / 2, -Math.PI / 2, true);
  p.lineTo(x - hx, y - r);
  p.absarc(x - hx, y, r, -Math.PI / 2, -Math.PI * 1.5, true);
  return p;
}
function roundedRectShape(w, h, r, cx = 0, cy = 0) {
  const s = new THREE.Shape(), x = cx - w / 2, y = cy - h / 2;
  s.moveTo(x + r, y);
  s.lineTo(x + w - r, y);
  s.absarc(x + w - r, y + r, r, -Math.PI / 2, 0, false);
  s.lineTo(x + w, y + h - r);
  s.absarc(x + w - r, y + h - r, r, 0, Math.PI / 2, false);
  s.lineTo(x + r, y + h);
  s.absarc(x + r, y + h - r, r, Math.PI / 2, Math.PI, false);
  s.lineTo(x, y + r);
  s.absarc(x + r, y + r, r, Math.PI, Math.PI * 1.5, false);
  return s;
}
function roundedRectPath(w, h, r, cx = 0, cy = 0) {
  const p = new THREE.Path(), x = cx - w / 2, y = cy - h / 2;
  p.moveTo(x + r, y + h);
  p.lineTo(x + w - r, y + h);
  p.absarc(x + w - r, y + h - r, r, Math.PI / 2, 0, true);
  p.lineTo(x + w, y + r);
  p.absarc(x + w - r, y + r, r, 0, -Math.PI / 2, true);
  p.lineTo(x + r, y);
  p.absarc(x + r, y + r, r, -Math.PI / 2, -Math.PI, true);
  p.lineTo(x, y + h - r);
  p.absarc(x + r, y + h - r, r, Math.PI, Math.PI / 2, true);
  return p;
}
// extrude a shape drawn in XY so it grows in +Y; shape +y maps to world -z
function extrudeUp(shape, depth, baseY = 0, bevel = 0) {
  const g = new THREE.ExtrudeGeometry(shape, {
    depth, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel,
    bevelOffset: 0, bevelSegments: 4, curveSegments: 28,
  });
  g.rotateX(-Math.PI / 2);
  g.computeBoundingBox();
  g.translate(0, baseY - g.boundingBox.min.y, 0);
  return g;
}
// extrude a shape drawn in XY along +Z (plate standing upright)
function extrudeZ(shape, depth, bevel = 0) {
  const g = new THREE.ExtrudeGeometry(shape, {
    depth, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel,
    bevelOffset: 0, bevelSegments: 4, curveSegments: 28,
  });
  g.computeBoundingBox();
  g.translate(0, 0, -g.boundingBox.min.z);
  return g;
}
const explode = (o, x, y, z, kind = 'lid') => {
  o.userData.explode = new THREE.Vector3(x, y, z);
  o.userData.kind = kind;
  return o;
};

function standoff(h, od, name) {
  const g = new THREE.Group(); g.name = name;
  const b = cyl(od / 2, h, M.black, name + '_boss', 24);
  b.position.y = h / 2;
  g.add(b);
  return g;
}
function screwM3(len, mat = M.steel, name = 'screw_m3') {
  const g = new THREE.Group(); g.name = name;
  const head = cyl(2.9, 2.2, mat, name + '_head', 24); head.position.y = 1.1;
  const shank = cyl(1.5, len, mat, name + '_shank', 20); shank.position.y = -len / 2;
  g.add(head, shank);
  return g;
}
// Dupont housing — 14 mm, the dominant clearance everywhere (CONNECTORS.md)
function dupont(ways, name) {
  return box(2.6 * ways, 14, 6.2, M.hdr, name);
}

/* ------------------------------------------------------------------ */
/* cable runs — tubes along Catmull-Rom curves                          */
/* ------------------------------------------------------------------ */
const W = {
  red: std('wire_red',    0xb32020, 0.62),
  blk: std('wire_black',  0x1b1b1e, 0.62),
  yel: std('wire_yellow', 0xd4ad24, 0.62),
  grn: std('wire_green',  0x2e8b3f, 0.62),
  org: std('wire_orange', 0xd07023, 0.66),
  brn: std('wire_brown',  0x5a3a22, 0.66),
};
function wire(pts, r, mat, name) {
  const curve = new THREE.CatmullRomCurve3(pts.map(p => new THREE.Vector3(...p)));
  return mesh(new THREE.TubeGeometry(curve, 48, r, 8), mat, name);
}
// 16 AWG power pair, red + black, slightly splayed
function powerPair(pts, name) {
  const g = new THREE.Group(); g.name = name;
  [[W.red, -1.4], [W.blk, 1.4]].forEach(([m, off]) =>
    g.add(wire(pts.map(p => [p[0], p[1], p[2] + off]), 1.1, m,
      name + (off < 0 ? '_red' : '_black'))));
  return g;
}
// I2C hookup bundle: 3V3 red, GND black, SDA yellow, SCL green
function i2cBundle(pts, name) {
  const g = new THREE.Group(); g.name = name;
  [[W.red, -2.4], [W.blk, -0.8], [W.yel, 0.8], [W.grn, 2.4]].forEach(([m, off], i) =>
    g.add(wire(pts.map(p => [p[0] + off, p[1], p[2]]), 0.7, m, name + '_' + i)));
  return g;
}
// servo lead: brown / red / orange ribbon
function servoTrio(pts, name) {
  const g = new THREE.Group(); g.name = name;
  [[W.brn, -1.6], [W.red, 0], [W.org, 1.6]].forEach(([m, off], i) =>
    g.add(wire(pts.map(p => [p[0] + off, p[1], p[2]]), 0.75, m, name + '_' + i)));
  return g;
}

/* ------------------------------------------------------------------ */
/* connectors — modelled including their BEHIND-panel volume           */
/* ------------------------------------------------------------------ */
// Amass XT60E-F panel mount: flange 34 x 16, Ø3 ears at 25 mm, body
// passes through and reaches ~9 mm behind + solder cups + 8 mm bend room.
// Local frame: flange face on the x = 0 plane, body reaching -x.
export function xt60eF() {
  const g = new THREE.Group(); g.name = 'XT60E_F_6V_inlet';
  const fl = box(2.2, 16, 34, M.red, 'xt60_flange');
  fl.position.x = 1.1; g.add(fl);
  const gasket = box(1.0, 16, 34, M.hdr, 'xt60_gasket'); g.add(gasket);
  const body = box(11, 13, 16.6, M.red, 'xt60_body');
  body.position.x = -5.5; g.add(body);
  for (const s of [-1, 1]) {
    const cup = box(9, 4.2, 6, M.silver, 'xt60_solder_cup');
    cup.position.set(-14.5, 0, s * 4.6); g.add(cup);
    const ear = cyl(3, 2.2, M.red, 'xt60_ear', 20);
    ear.rotation.z = Math.PI / 2; ear.position.set(1.1, 0, s * 12.5); g.add(ear);
  }
  return g;
}
// Inline XT60 service disconnect, mated pair ~24 x 8.2 x 8, lengthwise
export function xt60Inline() {
  const g = new THREE.Group(); g.name = 'XT60_service_disconnect';
  for (const s of [-1, 1]) {
    const half = box(11.6, 8, 8.2, M.red, 'xt60_inline_half');
    half.position.x = s * 6.1; g.add(half);
  }
  return g;
}
function barrelJack() {
  const g = new THREE.Group(); g.name = 'dc_barrel_jack_12V';
  const nut = cyl(5.8, 3, M.silver, 'jack_nut', 24); nut.rotation.z = Math.PI / 2; g.add(nut);
  const bar = cyl(4.2, 12, M.hdr, 'jack_barrel', 24);
  bar.rotation.z = Math.PI / 2; bar.position.x = 7; g.add(bar);
  const body = cyl(5.4, 14, M.hdr, 'jack_body', 24);
  body.rotation.z = Math.PI / 2; body.position.x = -8.5; g.add(body);
  return g;
}

/* ------------------------------------------------------------------ */
/* boards — PCB bottom face at y = 0, centred on origin                */
/* ------------------------------------------------------------------ */
// 30-pin devkit. Pins DOWN: Dupont housings hang 14 mm below the PCB, so
// the underside must sit >= 16.5 above the bay floor (CONNECTORS.md).
export function esp32Board() {
  const g = new THREE.Group(); g.name = 'ESP32_devkit';
  const L = 52.0, W = 28.9, T = 1.6;
  const pcb = box(L, T, W, M.pcbK, 'esp32_pcb'); pcb.position.y = T / 2; g.add(pcb);
  for (const s of [-1, 1]) {
    const h = box(46, 2.6, 2.6, M.hdr, 'esp32_header_housing');
    h.position.set(0, T + 1.3, s * (W / 2 - 2.0)); g.add(h);
    const p = box(46, 9.0, 0.7, M.pin, 'esp32_pins');
    p.position.set(0, -4.5, s * (W / 2 - 2.0)); g.add(p);
  }
  // hookup housings on the BACK row: D22 (pin 2), D21 (pin 5), GND/3V3 (14/15)
  for (const x of [-20.5, -13.0, 9.5]) {
    const d = dupont(x === 9.5 ? 2 : 1, 'esp32_dupont');
    d.position.set(x, -7.5, W / 2 - 2.0); g.add(d);
  }
  const can = box(18, 1.2, 16, M.silver, 'esp32_rf_can');
  can.position.set(-15, T + 0.6, 0); g.add(can);
  const usb = box(9.2, 3.2, 7.6, M.silver, 'esp32_usb_c_port');
  usb.position.set(L / 2 - 2.6, T + 1.6, 0); g.add(usb);
  const plug = box(10.5, 6.5, 10, M.hdr, 'esp32_usb_c_plug');
  plug.position.set(L / 2 + 5.2, T + 1.6, 0); g.add(plug);
  const soc = box(11, 1.1, 11, M.hdr, 'esp32_soc');
  soc.position.set(3, T + 0.55, 0); g.add(soc);
  for (const x of [16, 22]) {
    const b = cyl(1.9, 1.6, M.hdr, 'esp32_button', 16);
    b.position.set(x, T + 0.8, -9); g.add(b);
  }
  return g;
}

// BLUE clone. Chirality is fixed: with the I2C end (+x here) facing the
// ESP32, the 16-channel servo row lands on the BACK edge (+z here).
export function pca9685Board() {
  const g = new THREE.Group(); g.name = 'PCA9685_driver';
  const L = 62.5, W = 25.4, T = 1.6;
  const pcb = box(L, T, W, M.pcbB, 'pca_pcb'); pcb.position.y = T / 2; g.add(pcb);
  const base = box(52, 2.6, 7.8, M.hdr, 'pca_servo_header');
  base.position.set(2, T + 1.3, W / 2 - 5.2); g.add(base);
  for (let r = 0; r < 3; r++) {
    const row = box(52, 6, 0.7, M.pin, 'pca_servo_pins');
    row.position.set(2, T + 5.6, W / 2 - 7.8 + r * 2.54); g.add(row);
  }
  // six servo plugs, CH0-5, plug + lead bend ~14 mm above board top
  for (let i = 0; i < 6; i++) {
    const p = box(7.4, 13.6, 7.8, M.hdr, 'pca_servo_plug');
    p.position.set(-22 + i * 8.4, T + 8.4, W / 2 - 5.2); g.add(p);
  }
  // mid-board green V+/GND screw terminal — wires enter from ABOVE
  const tb = box(11, 9, 10, M.term, 'pca_v_plus_terminal');
  tb.position.set(-6, T + 4.5, -4); g.add(tb);
  const chip = box(9, 1.1, 9, M.hdr, 'pca_chip');
  chip.position.set(-22, T + 0.55, -5); g.add(chip);
  // right-angle 6-pin headers at BOTH ends: ~6 mm proud at ~10 mm height
  for (const s of [-1, 1]) {
    const e = box(3.0, 2.6, 15.2, M.hdr, 'pca_end_header');
    e.position.set(s * (L / 2 - 1.5), 8.4, -1); g.add(e);
    const ep = box(6.5, 0.7, 15.2, M.pin, 'pca_end_pins');
    ep.position.set(s * (L / 2 + 3.2), 8.4, -1); g.add(ep);
  }
  // I2C Dupont block on the ESP32-facing end: another ~14 mm horizontally
  const dp = box(14, 6.2, 12, M.hdr, 'pca_i2c_dupont');
  dp.position.set(L / 2 + 13, 8.4, -1); g.add(dp);
  return g;
}

// WAGO 221-415: 5-way lever clamp, 30 x 18.6 x 8.3 — wire entries face +x
export function wago221x5(name) {
  const g = new THREE.Group(); g.name = name;
  const body = box(18.6, 8.3, 30, M.wago, name + '_body');
  body.position.y = 4.15; g.add(body);
  const clear = box(6, 6.3, 29, M.silver, name + '_window');
  clear.position.set(7, 3.15, 0); g.add(clear);
  for (let i = 0; i < 5; i++) {
    const lv = box(7.5, 2.4, 4.4, M.hdr, name + '_lever');
    lv.position.set(-4.5, 9.4, -12 + i * 6);
    lv.rotation.z = 0.3; g.add(lv);
  }
  return g;
}

export function buckBoard() {
  const g = new THREE.Group(); g.name = 'buck_converter';
  const L = 65, W = 48, T = 1.6;
  const pcb = box(L, T, W, M.pcbB, 'buck_pcb'); pcb.position.y = T / 2; g.add(pcb);
  const hsBase = box(36, 2.5, 42, M.silver, 'buck_heatsink_base');
  hsBase.position.set(2, T + 1.25, 0); g.add(hsBase);
  for (let i = 0; i < 6; i++) {
    const fin = box(2.2, 11, 42, M.silver, 'buck_heatsink_fin');
    fin.position.set(-13 + i * 6, T + 8, 0); g.add(fin);
  }
  for (const s of [-1, 1]) {
    const tb = box(9, 9.5, 20, M.term, 'buck_terminal');
    tb.position.set(s * (L / 2 - 6), T + 4.75, -12); g.add(tb);
  }
  const ind = box(12, 8, 12, M.hdr, 'buck_inductor');
  ind.position.set(-22, T + 4, 14); g.add(ind);
  const pot = cyl(3.2, 4.5, M.pcbK, 'buck_trimpot', 20);
  pot.position.set(24, T + 2.25, 14); g.add(pot);
  return g;
}

/* ------------------------------------------------------------------ */
/* arm context stub — *** MEASURE ME ***                                */
/* Tower top-edge hole row (verified): screw-18-hole-18-hole-seam,       */
/* mirrored → holes at ±16 / ±34, proud arm screws at ±52.               */
/* ------------------------------------------------------------------ */
/* arm context stub — the REAL base: two bent L-brackets back-to-back      */
/* (see images/). Their feet bolt straight to the keel: NO arm mods.       */
export function armStub() {
  const g = new THREE.Group(); g.name = 'arm_context_stub';
  const AX = 14;
  for (const s of [-1, 1]) {
    const foot = mesh(extrudeUp(roundedRectShape(44, 92, 4, 0, 0), 2, 0), M.alu,
      'arm_bracket_foot' + (s < 0 ? '_a' : '_b'));
    foot.position.set(AX + s * 24, 0, 0);
    g.add(foot);
    const leg = box(2, 55, 92, M.alu, 'arm_bracket_leg' + (s < 0 ? '_a' : '_b'));
    leg.position.set(AX + s * 1.6, 2 + 27.5, 0);
    g.add(leg);
    for (const z of [-35, 35]) {   // proud assembly hardware on the legs
      const b = cyl(4.6, 3, M.steel, 'arm_proud_screw_head', 20);
      b.rotation.z = Math.PI / 2;
      b.position.set(AX + s * 4.1, 40, z);
      g.add(b);
    }
  }
  const servo = box(20, 38, 40, M.alu, 'arm_base_servo');
  servo.position.set(AX, 2 + 36, 0); g.add(servo);
  return g;
}

/* ------------------------------------------------------------------ */
/* CONCEPT A — KEEL: low ballast plinth under the base plate           */
/* ------------------------------------------------------------------ */
export function buildKeel({ boards = true, context = true, cables = {}, clamps = 'mounted' } = {}) {
  const g = new THREE.Group(); g.name = 'Concept_A_Keel';
  // v3: the space directly below the arm IS the electronics bay now.
  // Boards ride slide-out DRAWERS that exit the front wall, so nothing
  // needs open-sky lid access under the arm. ESP32 stands on its side
  // (pins inboard), which with the drawers sets H = 38 (v3.1: 2.6 mm air
  // over the upright board; sleds bear directly on the floor).
  const H = 38, FLOOR = 2.5, LID = 2.4, DECK = 2.4;
  const ARM_X = 40;                       // arm bracket feet datum
  const CH_X = -85, CH_L = 66, CH_W = 52; // aft power chamber (x -118..-52)
  const JT_X = -30, JT_W = 66;            // WAGO junction tray, centreline
  const DRW_Z = 27, DRW_W = 34;           // drawer tunnels at z +-27

  // Slim delta plan: 124 wide (was 192) x 208 long. Wide flat front edge
  // under the arm, flanks tapering aft to the transom.
  const outline = (notch = false, mouths = false) => {
    const s = new THREE.Shape();
    s.moveTo(-120, -34);
    s.quadraticCurveTo(-120, -44, -111, -47);
    s.bezierCurveTo(-100, -52, -70, -60, -40, -62);
    s.lineTo(74, -62);
    s.quadraticCurveTo(88, -62, 88, -48);
    if (mouths) {  // v3.3 drawer mouths: open bays in the outline itself
      // (holes that cross the outline edge don't triangulate, so the
      // front wall rendered SOLID before)
      s.lineTo(88, -44); s.lineTo(-5, -44); s.lineTo(-5, -10); s.lineTo(88, -10);
      s.lineTo(88, 10); s.lineTo(-5, 10); s.lineTo(-5, 44); s.lineTo(88, 44);
    }
    s.lineTo(88, 48);
    s.quadraticCurveTo(88, 62, 74, 62);
    s.lineTo(-40, 62);
    s.bezierCurveTo(-70, 60, -100, 52, -111, 47);
    s.quadraticCurveTo(-120, 44, -120, 34);
    if (notch) {   // v3.2 transom notch: the base's power wall fills it
      s.lineTo(-120, 30); s.lineTo(-116.5, 30);
      s.lineTo(-116.5, -30); s.lineTo(-120, -30);
    }
    s.lineTo(-120, -34);
    return s;
  };

  const floor = outline();
  for (const s of [-1, 1])
    for (let i = 0; i < 4; i++)                     // drawer tunnel vents
      floor.holes.push(slotPath(4 + i * 22, s * DRW_Z, 16, 3));
  for (let i = 0; i < 3; i++)                       // chamber vents
    floor.holes.push(slotPath(CH_X + 2, (i - 1) * 15, 40, 3));
  for (const s of [-1, 1]) floor.holes.push(slotPath(76, s * 56, 21, 11));
  // CLICK-OFF BASE: the whole floor (with feet) is a separate part — a
  // perimeter lip snaps up into the shell, then 4 side M3s secure it.
  // Pop it off and all wiring/connector work is open from below.
  const baseGrp = new THREE.Group(); baseGrp.name = 'keel_base_assembly';
  baseGrp.add(mesh(extrudeUp(floor, FLOOR, 0), M.black, 'keel_floor'));
  const lip = outline();
  lip.holes.push(roundedRectPath(196, 104, 12, -16, 0));
  const lipMesh = mesh(extrudeUp(lip, 3, FLOOR), M.black, 'keel_floor_snap_lip');
  lipMesh.scale.set(0.975, 1, 0.955);
  baseGrp.add(lipMesh);
  g.add(baseGrp);

  // shell: full height walls; chamber + junction open to the top (lidded),
  // drawer tunnels open to the FRONT (x = 88), covered by a fixed deck
  const shell = outline(true, true);
  shell.holes.push(roundedRectPath(CH_L - 5, CH_W, 6, CH_X + 2.5, 0));  // power chamber
  shell.holes.push(roundedRectPath(40, JT_W, 5, JT_X, 0));         // junction tray
  for (const s of [-1, 1]) {
    // (drawer tunnels are open-front bays in the outline itself; v3.3)
    shell.holes.push(roundedRectPath(30, 14, 5, -76, s * 40));      // ballast lobes
    shell.holes.push(slotPath(76, s * 56, 21, 11));                 // clamp slots
  }
  g.add(mesh(extrudeUp(shell, H - FLOOR - 1.4, FLOOR, 2.4), M.black, 'keel_shell'));
  // fixed vented deck over the drawer tunnels (the arm feet sit on this)
  for (const s of [-1, 1]) {
    const deck = roundedRectShape(96, DRW_W + 4, 4, 41, s * DRW_Z);
    for (let c = -4; c <= 4; c++) deck.holes.push(circPath(41 + c * 10, s * DRW_Z, 1.6));
    g.add(mesh(extrudeUp(deck, DECK, H - DECK), M.black, 'keel_deck_' + (s < 0 ? 'esp32' : 'pca9685')));
    // v3.2: tunnel mouths are open at the bottom, no sill; the drawers
    // and their guides ride the click-off base
  }
  // v3.1: M4 boss columns under the deck at the adapter screw points —
  // deck stiffeners at the arm-foot rows + full-depth head recesses
  for (const x of [16, 64]) for (const z of [-30, 30]) {
    const b = cyl(5, 6, M.black, 'keel_deck_boss', 24);
    b.position.set(x, H - DECK - 3, z);
    g.add(b);
  }
  // v3.4: lintels — the front-wall band ABOVE each drawer mouth (the
  // outline bays are full-height; the physical opening stops at the deck)
  for (const s of [-1, 1]) {
    const lin = box(3, DECK + 2, DRW_W + 4, M.black, 'keel_shell_mouth_lintel');
    lin.position.set(86.5, H - (DECK + 2) / 2, s * DRW_Z);
    g.add(lin);
  }

  // ballast lobe caps (red)
  for (const s of [-1, 1]) {
    const cap = roundedRectShape(36, 20, 7, -76, s * 40);
    cap.holes.push(slotPath(-76, s * 40, 14, 3));
    g.add(explode(mesh(extrudeUp(cap, LID, H - LID), M.red, 'keel_ballast_cap'),
      -20, 30, s * 6));
  }

  const clipTabs = (lidMesh, cx, cz, dx, dz) => {
    const grp = new THREE.Group(); grp.name = lidMesh.name + '_clips';
    for (const sx of [-1, 1]) for (const sz of [-1, 1]) {
      const t = box(6, 4.5, 1.6, M.white, 'keel_lid_clip');
      t.position.set(cx + sx * dx, H - LID - 2.2, cz + sz * dz);
      grp.add(t);
    }
    grp.userData.explode = lidMesh.userData.explode;
    grp.userData.kind = 'lid';
    return grp;
  };
  { // power chamber lid
    const lid = roundedRectShape(CH_L + 8, CH_W + 8, 8, CH_X, 0);
    for (let c = -3; c <= 3; c++)
      for (let r = -2; r <= 2; r++)
        lid.holes.push(circPath(CH_X + c * 9, r * 10.5, 1.8));
    const lm = explode(mesh(extrudeUp(lid, LID, H - LID), M.white, 'keel_lid_power'), 0, 40, 0);
    g.add(lm, clipTabs(lm, CH_X, 0, CH_L / 2 - 8, CH_W / 2 - 1));
  }
  { // junction tray lid. v3.7: the servo harness exits straight UP through
    // a bore in this lid at x = -17 — clear air above it, because the arm
    // adapter plate stops at x = -8 and the aft bracket foot at x = -6.
    // (An exit further fore would come up underneath the arm's own foot.)
    const lid = roundedRectShape(46, JT_W + 6, 6, JT_X, 0);
    lid.holes.push(circPath(-17, 0, 5.4));           // harness bore
    for (let r = -4; r <= 4; r++) lid.holes.push(circPath(JT_X - 15, r * 7, 1.6));
    lid.holes.push(roundedRectPath(8, 54, 2, JT_X, 0));
    const lm = explode(mesh(extrudeUp(lid, LID, H - LID), M.white, 'keel_lid_junction'), 0, 40, 14);
    g.add(lm, clipTabs(lm, JT_X, 0, 16, JT_W / 2 - 1));
    g.add(explode(mesh(extrudeUp(roundedRectShape(7.4, 53.4, 2, JT_X, 0), LID, H - LID),
      M.red, 'keel_lid_junction_motif'), 0, 40, 14));
  }
  // edge clamps: through-body slots inboard of the transom
  const makeClamp = (nm) => {
    const c = new THREE.Group(); c.name = nm;
    const head = box(30, 5, 26, M.black, 'clamp_t_head');
    head.position.set(-22, 6.5, 0); c.add(head);
    // flat-blade spine: 18 x 8 cross — wide face in the load plane, and
    // it actually passes the 21 x 11 through-slot; length = throat+4+H (94)
    const spine = box(18, 94, 8, M.black, 'clamp_spine');
    spine.position.set(-22, 4 - 94 / 2 + 9, 0); c.add(spine);
    const jaw = box(34, 8, 18, M.black, 'clamp_jaw');
    jaw.position.set(-9, -85, 0); c.add(jaw);
    // v3.4: two-piece clamp — the jaw bolts to the spine with 2× M4
    // (nothing one-piece fits through the 21 × 11 slot)
    for (const px of [-33, -11]) {
      const plate = box(4, 26, 12, M.black, 'clamp_jaw_splice_plate');
      plate.position.set(px, -70, 0); c.add(plate);
    }
    for (const sy of [-63, -77]) {
      const m4 = cyl(2.2, 30, M.steel, 'clamp_splice_m4', 16);
      m4.rotation.z = Math.PI / 2;
      m4.position.set(-22, sy, 0); c.add(m4);
    }
    const screw = cyl(3.2, 16, M.steel, 'clamp_m6_thumbscrew', 20);
    screw.position.set(0, -75, 0); c.add(screw);
    const knob = cyl(11, 6, M.red, 'clamp_hand_knob', 8);
    knob.position.set(0, -84, 0); c.add(knob);
    const pad = cyl(7, 2.5, M.aqua, 'clamp_pad_tpu', 24);
    pad.position.set(0, -65.7, 0); c.add(pad);
    return c;
  };
  for (const s of [-1, 1]) {
    for (const hx of [20, 64]) {   // stow clip posts + lips over the spines
      const post = box(6, 20, 3, M.black, 'clamp_stow_hook');
      post.position.set(hx, H + 10, s * 57);
      const lip = box(6, 3, 7, M.black, 'clamp_stow_hook_lip');
      lip.position.set(hx, H + 18.5, s * 53.5);
      g.add(post, lip);
    }
    const c = makeClamp('desk_clamp' + (s < 0 ? '_left' : '_right'));
    if (clamps === 'mounted') {
      // jaw reaches back INBOARD under the benchtop (the arm end — opposite
      // the connector nose); clamp corners overhang the bench edge ~20 mm (v3.2)
      c.rotation.y = Math.PI;   // v3.2: jaw + screw reach INBOARD
      c.position.set(54, H - 4, s * 56);
    } else {
      // stowed (v3.2): folded FLAT on the deck, arms INBOARD — heads inboard,
      // T-heads at the flank edges, clipped under the stow lips.
      const m = new THREE.Matrix4().makeBasis(
        new THREE.Vector3(0, 0, -s),          // local +x (arm side) -> inboard
        new THREE.Vector3(-s, 0, 0),          // spine axis along the deck
        new THREE.Vector3(0, 1, 0));          // clamp thickness -> up
      c.quaternion.setFromRotationMatrix(m);
      c.position.set(s > 0 ? 1 : 79, H + 13.4, s * 24);
    }
    g.add(c);
  }

  // drawers: sled + red face plate, sliding out the front on wall rails
  const drawer = (nm, cz) => {
    const grp = new THREE.Group(); grp.name = nm;
    const plate = box(72, 1.6, DRW_W - 6, M.red, nm + '_sled');
    plate.position.set(50, FLOOR + 0.8, cz); grp.add(plate);
    const face = box(2.4, H - FLOOR - DECK - 4, DRW_W + 2, M.red, nm + '_face');
    face.position.set(87.2, FLOOR + (H - FLOOR - DECK) / 2 - 1, cz); grp.add(face);
    const pull = box(6, 4, 16, M.white, nm + '_finger_pull');
    pull.position.set(89.5, FLOOR + 14, cz); grp.add(pull);
    return grp;
  };
  for (const s of [-1, 1])   // floor-level side guides — part of the base
    for (const e of [-1, 1]) {
      const r = box(78, 5, 2.5, M.black, 'keel_drawer_guide');
      r.position.set(48, FLOOR + 2.5, s * DRW_Z + e * (DRW_W / 2 - 1.25));
      baseGrp.add(r);
    }
  if (boards) {
    // ESP32 drawer: board ON ITS SIDE, pins facing INBOARD, USB-C to the face
    const eDrw = drawer('keel_drawer_esp32', -DRW_Z);
    const e = esp32Board();
    e.rotation.z = Math.PI;              // flip so...
    e.rotation.x = Math.PI / 2;          // ...PCB stands vertical
    e.position.set(40, FLOOR + 2 + 15.5, -DRW_Z + 6);
    eDrw.add(e);
    const eCradle = box(60, 26, 3, M.red, 'keel_drawer_esp32_cradle');
    eCradle.position.set(40, FLOOR + 15, -DRW_Z + 9.5);
    eDrw.add(eCradle);
    const usbWin = box(1, 5.5, 10.5, M.hdr, 'keel_drawer_esp32_usb_window');
    usbWin.position.set(88.5, FLOOR + 16, -DRW_Z);
    eDrw.add(usbWin);
    g.add(explode(eDrw, 46, 0, 0, 'board'));
    baseGrp.add(eDrw);
    // PCA drawer: flat, servo row outboard, I2C end aft toward the junction
    const pDrw = drawer('keel_drawer_pca9685', DRW_Z);
    const p = pca9685Board();
    p.position.set(40, FLOOR + 4, DRW_Z - 2);
    p.rotation.y = Math.PI;
    pDrw.add(p);
    for (const px of [-1, 1]) for (const pz of [-1, 1]) {
      const so = cyl(2.9, 2.4, M.red, 'keel_drawer_pca_standoff', 20);
      so.position.set(40 + px * 28, FLOOR + 2.8, DRW_Z - 2 + pz * 9.5);
      pDrw.add(so);
    }
    g.add(explode(pDrw, 46, 0, 0, 'board'));
    baseGrp.add(pDrw);
    // buck on a sled in the aft chamber
    const bSled = new THREE.Group(); bSled.name = 'keel_sled_buck';
    const bPlate = box(CH_L - 10, 1.6, CH_W - 8, M.red, 'keel_sled_buck_plate');
    bPlate.position.set(CH_X, FLOOR + 0.8, 0); bSled.add(bPlate);
    const b = buckBoard();
    b.position.set(CH_X, FLOOR + 4, 0);
    bSled.add(b);
    g.add(explode(bSled, 0, 24, 0, 'board'));
    baseGrp.add(bSled);
    const husb = box(22, 3.5, 18, M.pcbB, 'husb238_stemma_qt');
    husb.position.set(-112, 22, 14);
    baseGrp.add(explode(husb, -10, 20, 4, 'board'));
    const oring = box(20, 3.5, 15, M.term, 'pololu_oring_pair');
    oring.position.set(-112, 22, -12);
    baseGrp.add(explode(oring, -10, 20, -4, 'board'));
    // WAGO junction, centreline: two separated lanes, + aft / - fore
    for (let r = 0; r < 2; r++) {
      const lane = r === 0 ? 'plus' : 'minus';
      const lx = JT_X - 10 + r * 19;
      const ramp = box(15, 2.5, JT_W - 4, M.black, 'keel_wago_rail_' + lane);
      ramp.rotation.z = 0.7;
      ramp.position.set(lx, FLOOR + 5, 0);
      baseGrp.add(ramp);
      // v3.3 (pixelwave-style junction, our own geometry): one clip fin
      // at each end of EACH 221-415, so any single clamp unsnaps alone
      for (const cy of [-31.8, 0, 31.8]) {
        const fin = box(4.5, 16, 1.6, M.black, 'keel_wago_clip_' + lane);
        fin.rotation.z = 0.7;
        fin.position.set(lx - 1.5, FLOOR + 7, cy);
        baseGrp.add(fin);
      }
      for (let c = 0; c < 2; c++) {
        const tilt = new THREE.Group();
        tilt.name = 'wago_' + lane + '_rail_' + (c ? 'b' : 'a');
        const w = wago221x5(tilt.name + '_clamp');
        w.position.y = -4.15;
        tilt.add(w);
        tilt.rotation.z = 0.7;
        tilt.position.set(lx + 1, FLOOR + 7.5, -15.5 + c * 31);
        baseGrp.add(explode(tilt, 0, 16 + r * 6, 6, 'board'));
      }
    }
  }

  /* ---------------- v3.6 COUPLER COMB ------------------------------- *
   * The arm's six servo leads end in standard 3-pin Dupont sockets
   * (2.54 pitch, 7.5 mm wide housings). Each lands in its own channel of
   * a red comb that drops into grooves in the junction-tray walls, ABOVE
   * the WAGO lanes. Per channel, running aft -> fore:
   *   [end stop] [PCA-side MALE pigtail plug] --pins--> [ARM-side FEMALE]
   * The male half is captive against the end stop, so pulling the arm
   * plug can never drag the drawer's pigtail out. A hinged latch bar
   * closes over all six and holds them down; flip it up and the whole
   * arm harness detaches in six straight pulls. Lift the comb out on its
   * tongues (leads still attached) for full WAGO access underneath.
   * ------------------------------------------------------------------ */
  const CMB_X = JT_X, CMB_Y = 20, PITCH = 9.6, CH_N = 6;
  const chZ = (i) => (i - (CH_N - 1) / 2) * PITCH;   // channel centrelines
  const comb = new THREE.Group(); comb.name = 'keel_coupler_comb';
  const combPlate = box(38, 3, 64, M.red, 'comb_plate');
  combPlate.position.set(CMB_X, CMB_Y + 1.5, 0); comb.add(combPlate);
  // 7 dividers -> six 7.8 mm channels; flared lead-ins at the arm mouth
  for (let i = 0; i <= CH_N; i++) {
    const z = (i - CH_N / 2) * PITCH;
    const rib = box(32, 9, 1.8, M.red, 'comb_divider');
    rib.position.set(CMB_X - 1, CMB_Y + 7.5, z); comb.add(rib);
    const flare = box(5, 5.5, 3.4, M.red, 'comb_lead_in_flare');
    flare.position.set(CMB_X + 17, CMB_Y + 5.75, z); comb.add(flare);
  }
  // aft end stop — the captive male pigtail plugs butt against this
  const stop = box(3, 9, 64, M.red, 'comb_pigtail_end_stop');
  stop.position.set(CMB_X - 18, CMB_Y + 7.5, 0); comb.add(stop);
  // channel index pips (1..6) moulded on the fore lip
  for (let i = 0; i < CH_N; i++)
    for (let p = 0; p <= i; p++) {
      const pip = box(1.4, 1, 1.4, M.red, 'comb_channel_pip');
      pip.position.set(CMB_X + 12.5 - p * 2.4, CMB_Y + 3.5, chZ(i));
      comb.add(pip);
    }
  // hinge knuckles for the latch bar + the catch ledge it snaps into
  for (const z of [-22, 0, 22]) {
    const k = cyl(1.7, 7, M.red, 'comb_hinge_knuckle', 16);
    k.rotation.x = Math.PI / 2;
    k.position.set(CMB_X - 17, CMB_Y + 4.5, z); comb.add(k);
  }
  const ledge = box(2.5, 2.5, 14, M.red, 'comb_latch_catch_ledge');
  ledge.position.set(CMB_X + 15.5, CMB_Y + 4.2, 0); comb.add(ledge);
  // side tongues: ride grooves in the tray walls, lift straight out
  for (const s of [-1, 1]) {
    const t = box(30, 2.6, 3, M.red, 'comb_rail_tongue');
    t.position.set(CMB_X, CMB_Y + 1.5, s * 33); comb.add(t);
    const lift = box(6, 3, 9, M.red, 'comb_finger_lift');
    lift.position.set(CMB_X + 21, CMB_Y + 1.5, s * 25); comb.add(lift);
  }
  g.add(explode(comb, 0, 34, -10));

  // hinged latch bar — group origin sits ON the hinge axis so it can be
  // swung open (comb view rotates it about Z)
  const latch = new THREE.Group(); latch.name = 'comb_latch_bar';
  latch.position.set(CMB_X - 17, CMB_Y + 4.5, 0);
  const lbeam = box(34, 2.6, 64, M.red, 'comb_latch_beam');
  lbeam.position.set(16, 7, 0); latch.add(lbeam);
  for (let i = 0; i < CH_N; i++) {   // per-channel hold-down pads
    const pad = box(30, 1.6, 7.4, M.red, 'comb_latch_holddown');
    pad.position.set(15, 4.9, chZ(i)); latch.add(pad);
  }
  const hook = box(3, 6, 14, M.red, 'comb_latch_hook');
  hook.position.set(33.5, 4.5, 0); latch.add(hook);
  const barb = box(2.4, 1.6, 14, M.red, 'comb_latch_barb');
  barb.position.set(32.2, 2, 0); latch.add(barb);
  for (const z of [-11, 11]) {
    const k = cyl(1.7, 7, M.red, 'comb_latch_knuckle', 16);
    k.rotation.x = Math.PI / 2;
    k.position.set(0, 0, z); latch.add(k);
  }
  g.add(explode(latch, 0, 44, -8));

  if (boards) for (let i = 0; i < CH_N; i++) {
    const z = chZ(i), y = CMB_Y + 6.2;   // housings sit on the comb floor
    // PCA-side pigtail: MALE 3-pin, captive against the end stop
    const male = box(9, 6.2, 7.4, M.hdr, 'dupont_male_pca_ch' + i);
    male.position.set(CMB_X - 12, y, z); g.add(male);
    for (let p = -1; p <= 1; p++) {
      const pin = box(8, 0.64, 0.64, M.pin, 'dupont_pin_ch' + i);
      pin.position.set(CMB_X - 3.5, y, z + p * 2.54); g.add(pin);
    }
    // ARM-side harness plug: FEMALE 3-pin — this is the half you unplug
    const fem = box(14.5, 6.4, 7.5, M.hdr, 'dupont_female_arm_ch' + i);
    fem.position.set(CMB_X + 0.5, y, z);
    g.add(explode(fem, 18, 26, 0, 'board'));
    const key = box(14.5, 1, 1.6, M.red, 'dupont_female_key_ch' + i);
    key.position.set(CMB_X + 0.5, y + 3.7, z);
    g.add(explode(key, 18, 26, 0, 'board'));
    // colour-coded 3-lead tails, both sides (signal / +6V / GND)
    const cols = [W.org, W.red, W.blk];
    for (let p = -1; p <= 1; p++) {
      const a = box(10, 1.3, 1.3, cols[p + 1], 'lead_arm_ch' + i);
      a.position.set(CMB_X + 12.8, y, z + p * 2.54);
      g.add(explode(a, 18, 26, 0, 'board'));
      const b = box(10, 1.3, 1.3, cols[p + 1], 'lead_pca_ch' + i);
      b.position.set(CMB_X - 21.5, y, z + p * 2.54); g.add(b);
    }
  }
  // service windows: the PCA pigtails (and the ESP32's I2C/power tail)
  // pass from the drawer tunnels into the junction tray through the
  // dividing wall, so drawers roll out without opening the tray
  for (const s of [-1, 1]) {
    const win = box(5.4, 14, 20, M.hdr,
      'keel_pigtail_pass_' + (s < 0 ? 'esp32' : 'pca9685'));
    win.position.set(-7.5, 24, s * DRW_Z);
    g.add(win);
  }

  // transom power wall: PART OF THE BASE (v3.2). The jack + USB-C
  // extensions panel-mount here and wire to boards on the base, so the
  // whole power end comes away with the click-off floor.
  const transom = box(3.2, H - FLOOR - LID, 59.4, M.black, 'keel_base_transom');
  transom.position.set(-118.3, FLOOR + (H - FLOOR - LID) / 2, 0);
  baseGrp.add(transom);
  const panel = box(1.4, 17, 46, M.red, 'keel_io_panel');
  panel.position.set(-120.2, FLOOR + 14, 1);
  baseGrp.add(panel);
  const jack = barrelJack();
  jack.rotation.y = Math.PI;
  jack.position.set(-121, FLOOR + 14, -14);
  baseGrp.add(jack);
  for (const [z, nm] of [[2, 'usb_c_pd_in'], [17, 'usb_c_service']]) {
    const u = box(3.4, 4.5, 10, M.silver, nm);
    u.position.set(-121, FLOOR + 14, z);
    baseGrp.add(u);
  }

  // v3.5: servo egress on the CENTRELINE, at the arm-side edge of the
  // junction lid — slit TPU edge bushing (U-notch in the lid + relief in
  // the shell rim) so the harness never bears on a printed PETG edge;
  // unclip the bushing and the lid lifts off past the cables
  // v3.7: servo egress through the JUNCTION LID at x = -17 — sited
  // deliberately AFT of the arm adapter plate (aft edge x = -8) and of the
  // arm's own aft bracket foot (aft edge x = -6), so the harness rises into
  // open air and nothing overhangs the bore. Slit TPU bushing presses in;
  // unplug the six comb joints and the lid lifts off, harness with the arm.
  const gromNeck = cyl(5.2, 9, M.aqua, 'keel_edge_bushing_tpu', 28);
  gromNeck.position.set(-17, H - 2, 0);
  const gromFlange = cyl(7, 2, M.aqua, 'keel_edge_bushing_flange_tpu', 28);
  gromFlange.position.set(-17, H + 1.6, 0);
  g.add(gromNeck, gromFlange);

  // ARM ADAPTER PLATE: separately printed (red), carries the two bracket
  // feet; M4 screws come up FROM BELOW (through deck bosses, reachable via
  // the drawer tunnels) into heat-sets in the adapter — fit-test and
  // future-arm swaps without reprinting the body.
  const adapter = box(96, 4, 86, M.red, 'arm_adapter_plate');
  adapter.position.set(40, H + 2, 0);
  g.add(explode(adapter, 0, 26, 0, 'board'));
  // its four M4s, inserted FROM BELOW through the deck bosses
  for (const x of [16, 64]) for (const z of [-30, 30]) {
    const s = screwM3(12, M.steel, 'adapter_m4_from_below');
    s.rotation.x = Math.PI;
    s.position.set(x, H - DECK - 7, z);
    g.add(explode(s, 0, -10, 0, 'board'));
  }

  for (const x of [16, 64]) for (const z of [-30, 30]) {
    const s = screwM3(10); s.position.set(x, H + 4.2, z); g.add(s);
  }
  for (const [x, z] of [[-106, -26], [-106, 26], [56, -50], [56, 50]]) {
    const f = cyl(11, 4, M.aqua, 'keel_foot_tpu', 28);
    f.position.set(x, -2, z);
    baseGrp.add(f);
  }
  // v3.2: 4 countersunk M3s FROM BELOW through the floor into shell-wall
  // bosses, fastenable from outside with the keel on the bench
  for (const [x, hz] of [[-70, 51.8], [40, 57.8]]) for (const s of [-1, 1]) {
    const sc = screwM3(9, M.steel, 'base_bottom_screw');
    sc.rotation.x = Math.PI;
    sc.position.set(x, 1.2, s * hz);
    baseGrp.add(sc);
  }

  if (context) {
    const arm = armStub();
    arm.position.set(ARM_X - 14, H + 4, 0);
    g.add(explode(arm, 0, 52, 0, 'board'));   // lifts clear of the adapter on service
  }

  // ---- cable runs ----
  if (cables.pwr) {
    g.add(wire([[-117, 17, -14], [-110, 19, -14], [-104, 20, -12]], 1.2, W.blk,
      'cable_12v_stub'));
    g.add(powerPair([[-60, 8, 0], [-54, 7, 0], [-44, 12, -4]], 'cable_6v_to_junction'));
    g.add(powerPair([[-24, 14, -16], [-6, 8, -24], [12, 10, -27]], 'cable_6v_esp_vin'));
  }
  if (cables.i2c) {
    // ESP32 drawer -> around the drawer tails -> PCA I2C end
    g.add(i2cBundle([[14, 14, -27], [-4, 10, -14], [-8, 10, 14], [8, 12, 27]], 'cable_i2c'));
  }
  if (cables.servo) {
    g.add(wire([[-30, 26, -8], [-16, 30, -4], [-8, 36, -2]], 1.5,
      W.red, 'cable_trunk_plus'));
    g.add(wire([[-30, 26, 8], [-16, 30, 4], [-8, 36, 2]], 1.5,
      W.blk, 'cable_trunk_minus'));
    for (let i = 0; i < 6; i++) {
      const x = 60 - 8 * i;
      g.add(wire([[x, 24, 38], [10, 30, 24], [-8, 37, 3]], 0.75, W.org,
        'cable_servo_sig_ch' + i));
    }
    for (let i = 0; i < 6; i++)
      g.add(servoTrio([[-17, 41, 0], [-6, 58, 10],
        [14 + (i - 2.5) * 5, 78, 2]], 'cable_servo_ch' + i));
  }

  g.userData.spec = {
    name: 'A \u00b7 KEEL', tag: 'SELECTED \u2014 integrated base',
    dims: '208 \u00d7 124 \u00d7 38 mm (+4 mm TPU feet)',
    lines: [
      '<strong>The space under the arm is now the electronics bay:</strong> both logic boards ride <strong>slide-out drawers</strong> that exit the front wall between floor-level guides \u2014 red faces, finger pulls, printed detents click them home. Tunnel mouths are open at the bottom \u2014 drawers ride the base out. Width drops 192 \u2192 124 mm.',
      'ESP32 stands <strong>on its side, pins inboard</strong> in a cradle (USB-C at the drawer face); PCA9685 lies flat, servo row outboard, I2C end aft toward the junction. Buck on its own sled in the aft chamber.',
      'WAGO junction on the centreline: two separated lanes (+ aft, \u2212 fore, gully between), each two bridged 221-415s at \u224840\u00b0 in per-clamp clip fins (any one pops off alone; pixelwave-style, own geometry), levers up, serviceable with the tray lid off.',
      '<strong>Coupler comb (v3.6):</strong> the arm harness ends in <strong>six 3-pin Dupont sockets</strong> (2.54 pitch) — one per servo. Each drops into its own 7.8 mm channel of a red comb that sits in tray-wall grooves <strong>above</strong> the WAGO lanes. Aft in every channel is the PCA drawer’s <strong>male</strong> pigtail plug, held captive against a moulded end stop so pulling the arm side can never drag it out; the arm’s <strong>female</strong> plug pushes on from the fore side through a flared lead-in. A <strong>hinged latch bar</strong> flips down over all six with a per-channel hold-down pad and one snap catch. Flip it up — the whole arm detaches in six straight pulls; lift the comb out on its tongues (leads attached) for full WAGO access. Channels are numbered 1–6 in moulded pips.',
      '<strong>Harness egress (v3.7):</strong> a Ø10.4 mm bore straight up through the <strong>junction lid</strong> at x = −17, with an aqua slit <strong>TPU bushing</strong> pressed in. It is sited deliberately <strong>aft of the arm adapter plate</strong> (aft edge x = −8) and of the arm’s own aft bracket foot (x = −6) — the harness rises into clear air with nothing overhanging it, and the bore lines up directly over the comb’s fore lead-outs. Unplug the six comb joints and the lid lifts straight off. Drawer pigtails reach the tray through <strong>service windows</strong> in the tunnel/tray dividing wall.',
      'Edge clamps mount <strong>through slots in the body</strong> at the WIDE edge — the arm end, opposite the connector nose (T-head in the deck recess, whole-shell load path): the clamp corners overhang the bench edge ~20 mm (front feet sit inboard, still on the bench) and the <strong>jaw + M6 thumbscrew reach back INBOARD under the benchtop</strong>, clamping the keel onto the bench it sits on. Installs from above: spine through the slot, then the jaw bolts on below with 2× M4 nuts (the extension splices into the same joint for thick tops); M6 thumbscrew is hand-tight — no screws into the body. Stowed, they fold <strong>flat on the deck, arms inboard</strong>, clipped under printed stow lips — nothing below the floor, base sits flush.',
      '<strong>Separately printed arm adapter plate</strong> (red, 96 × 86 × 4): the two stock bracket feet bolt to it; four M4s come up from below through deck bosses (reachable via the drawer tunnels) into heat-sets — fit-tests and future arms swap the adapter, not the body. Four M4 boss columns under the deck double as its stiffeners at the foot rows.',
      '<strong>Transom power wall is part of the base</strong> (v3.2): the dual inlet (12 V jack / USB-C PD via HUSB238 + ORing pair) + USB-C service port rise from the click-off floor into a shell notch (the chamber lid caps the joint), so the power end comes away wiring-intact. Servo harness exits through an aqua <strong>TPU edge bushing on the centreline, at the junction-lid edge</strong> (v3.5) — unclip it and the lid lifts off past the cables.',
      'The <strong>whole base clicks off</strong>: the floor (feet attached) snaps up into the shell on a perimeter lip and locks with <strong>4 countersunk M3s from below</strong> (fastenable from outside; TPU feet keep the heads clear) — pop it off (BASE toggle) and every wire run and connector is open from below (wires route the tunnel/tray corners; no floor raceways).',
      'Two ballast lobes aft (~200 g shot) under red coin-slot caps.',
    ],
    parts: 'keel_floor + keel_shell + decks (black PETG) \u00b7 2 lids (white) \u00b7 caps + drawers + comb + latch bar + I/O panel (red) \u00b7 feet + edge bushing (aqua TPU)',
  };
  return g;
}

// shared helpers re-exported for mounts-archive.js (concepts B + C)
export { mesh, box, cyl, circPath, slotPath, roundedRectShape, roundedRectPath,
         extrudeUp, extrudeZ, explode, standoff, screwM3, W, wire, powerPair,
         i2cBundle, servoTrio, barrelJack };

export const CONCEPTS = { keel: buildKeel };
