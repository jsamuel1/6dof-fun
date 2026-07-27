/* ------------------------------------------------------------------ *
 * PARTS VIEW — every separately printed component, broken out of the
 * assembly and laid on a flat grid with a label. Nothing is re-modelled:
 * meshes are lifted from the real build, so the parts view can never
 * drift from the assembly.
 * ------------------------------------------------------------------ */
import * as THREE from 'three';
import { buildKeel } from './mounts.js';

/* Each entry claims meshes by name. `one:true` keeps a single specimen of
 * each named mesh (feet ×4, clamps ×2 … show once, qty in the label). */
const PARTS = [
  { id: 'floor', label: 'BASE FLOOR', qty: 1, mat: 'PETG black',
    note: 'flat on bed · feet-side down',
    re: /^(keel_floor|keel_floor_snap_lip|keel_drawer_guide|keel_base_transom|keel_wago_rail_|keel_wago_clip_)/ },
  { id: 'shell', label: 'SHELL', qty: 1, mat: 'PETG black',
    note: 'deck-down · supports in bays only',
    re: /^(keel_shell$|keel_shell_mouth_lintel|keel_deck_|clamp_stow_hook)/ },
  { id: 'lidpwr', label: 'POWER LID', qty: 1, mat: 'PETG white',
    note: 'flat · no supports',
    re: /^(keel_lid_power|keel_lid_power_clips)/, parent: /keel_lid_power/ },
  { id: 'lidjt', label: 'JUNCTION LID', qty: 1, mat: 'PETG white',
    note: 'ø10.4 harness bore · flat',
    re: /^keel_lid_junction($|_clips)/, parent: /keel_lid_junction/ },
  { id: 'lidclip', label: 'LID CLIP', qty: 8, mat: 'PETG white',
    note: 'printed on the lids', re: /^keel_lid_clip$/, one: true },
  { id: 'motif', label: 'LID ± MOTIF', qty: 1, mat: 'PETG red',
    note: 'inlay · swap at layer change', re: /^keel_lid_junction_motif$/ },
  { id: 'cap', label: 'BALLAST CAP', qty: 2, mat: 'PETG red',
    note: 'coin-slot up · ~200 g shot below', re: /^keel_ballast_cap$/, one: true },
  { id: 'drwE', label: 'ESP32 DRAWER', qty: 1, mat: 'PETG red',
    note: 'face-down · cradle needs no support', re: /^keel_drawer_esp32/ },
  { id: 'drwP', label: 'PCA9685 DRAWER', qty: 1, mat: 'PETG red',
    note: 'face-down · 4 printed standoffs', re: /^keel_drawer_pca9685|^keel_drawer_pca_standoff$/ },
  { id: 'sled', label: 'BUCK SLED', qty: 1, mat: 'PETG red',
    note: 'flat', re: /^keel_sled_buck_plate$/ },
  { id: 'comb', label: 'COUPLER COMB', qty: 1, mat: 'PETG red',
    note: 'channels up · 6 × 3-pin Dupont', re: /^comb_(plate|divider|lead_in_flare|pigtail_end_stop|channel_pip|hinge_knuckle|latch_catch_ledge|rail_tongue|finger_lift)$/ },
  { id: 'latch', label: 'COMB LATCH BAR', qty: 1, mat: 'PETG red',
    note: 'pads down · living hinge pin ø3.4', re: /^comb_latch_(beam|holddown|hook|barb|knuckle)$/ },
  { id: 'panel', label: 'I/O PANEL', qty: 1, mat: 'PETG red',
    note: 'flat · jack + 2 × USB-C cutouts', re: /^keel_io_panel$/ },
  { id: 'adapter', label: 'ARM ADAPTER', qty: 1, mat: 'PETG red',
    note: 'flat · 4 × M4 heat-sets', re: /^arm_adapter_plate$/ },
  { id: 'spine', label: 'CLAMP SPINE', qty: 2, mat: 'PETG black',
    note: 'upright · T-head down', re: /^(clamp_t_head|clamp_spine)$/, one: true },
  { id: 'jaw', label: 'CLAMP JAW', qty: 2, mat: 'PETG black',
    note: 'flat · 2 × M4 through', re: /^(clamp_jaw|clamp_jaw_splice_plate)$/, one: true },
  { id: 'knob', label: 'THUMBSCREW KNOB', qty: 2, mat: 'PETG red',
    note: 'M6 heat-set / captive nut', re: /^clamp_hand_knob$/, one: true },
  { id: 'foot', label: 'FOOT', qty: 4, mat: 'TPU aqua',
    note: '95A · 0.2 mm layers', re: /^keel_foot_tpu$/, one: true },
  { id: 'bush', label: 'EDGE BUSHING', qty: 1, mat: 'TPU aqua',
    note: 'slit to the bore · press fit', re: /^keel_edge_bushing/ },
];

function labelSprite(part) {
  const c = document.createElement('canvas');
  c.width = 700; c.height = 200;
  const x = c.getContext('2d');
  x.fillStyle = '#1b1c1f';
  x.font = '600 54px "IBM Plex Mono", monospace';
  x.textAlign = 'center';
  x.fillText(part.label + (part.qty > 1 ? '  ×' + part.qty : ''), 350, 56);
  x.fillStyle = '#b0271f';
  x.font = '500 38px "IBM Plex Mono", monospace';
  x.fillText(part.mat, 350, 110);
  x.fillStyle = '#5b5d63';
  x.font = '400 34px "IBM Plex Sans", sans-serif';
  x.fillText(part.note, 350, 162);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: t, transparent: true, depthTest: false }));
  s.scale.set(70, 20, 1);
  s.name = 'label_' + part.id;
  return s;
}

export function buildParts() {
  const src = buildKeel({ boards: true, context: false, clamps: 'mounted' });
  src.updateMatrixWorld(true);

  const buckets = new Map();
  src.traverse(o => {
    if (!o.isMesh) return;
    const def = PARTS.find(p => p.re.test(o.name));
    if (!def) return;
    let b = buckets.get(def.id);
    if (!b) buckets.set(def.id, b = { def, grp: new THREE.Group(), seen: new Set() });
    if (def.one) { if (b.seen.has(o.name)) return; b.seen.add(o.name); }
    const m = new THREE.Mesh(o.geometry, o.material);
    m.name = o.name;
    o.matrixWorld.decompose(m.position, m.quaternion, m.scale);
    b.grp.add(m);
  });

  // measure, then flatten each part to sit on y = 0 centred on its cell
  const tiles = [];
  for (const { def, grp } of buckets.values()) {
    grp.name = 'part_' + def.id;
    grp.updateMatrixWorld(true);
    const bb = new THREE.Box3().setFromObject(grp);
    const c = bb.getCenter(new THREE.Vector3()), sz = bb.getSize(new THREE.Vector3());
    for (const m of grp.children) { m.position.x -= c.x; m.position.y -= bb.min.y; m.position.z -= c.z; }
    tiles.push({ def, grp, w: Math.max(sz.x, 74), d: sz.z, h: sz.y });
  }
  tiles.sort((a, b) => b.w * b.d - a.w * a.d);

  // greedy row packing
  const GAP = 26, MAXW = 430, rows = [];
  let row = [], rw = 0;
  for (const t of tiles) {
    if (row.length && rw + GAP + t.w > MAXW) { rows.push({ row, rw }); row = []; rw = 0; }
    rw += (row.length ? GAP : 0) + t.w;
    row.push(t);
  }
  if (row.length) rows.push({ row, rw });

  const g = new THREE.Group(); g.name = 'Keel_printed_parts';
  let z = 0;
  for (const { row: r, rw } of rows) {
    const rd = Math.max(...r.map(t => t.d));
    let x = -rw / 2;
    for (const t of r) {
      t.grp.position.set(x + t.w / 2, 0, z + rd / 2);
      g.add(t.grp);
      const lab = labelSprite(t.def);
      lab.position.set(x + t.w / 2, 4, z + rd + 13);
      g.add(lab);
      x += t.w + GAP;
    }
    z += rd + 42;
  }
  g.position.z = -z / 2;

  const n = tiles.reduce((a, t) => a + t.def.qty, 0);
  g.userData.spec = {
    name: 'A · KEEL — PRINTED PARTS', tag: `${tiles.length} unique · ${n} pieces`,
    dims: 'largest part: shell 208 × 124 × 36 mm',
    lines: [
      `<strong>${tiles.length} distinct printed parts, ${n} pieces total</strong> — every one lifted straight from the assembly model, so this sheet cannot drift from the design.`,
      '<strong>PETG black (2 parts):</strong> base floor (feet, drawer guides, WAGO rails and the transom power wall all print with it) and the shell (decks, lintels, stow hooks integral). Both are single-piece prints; only the drawer bays need support.',
      '<strong>PETG white (2 + clips):</strong> power lid and junction lid. The junction lid carries the U-notch that lets it lift off past the servo harness.',
      '<strong>PETG red (10 parts):</strong> the service set — two drawers, buck sled, coupler comb + its latch bar, I/O panel, arm adapter, two ballast caps, thumbscrew knobs, ± motif inlay. Anything you touch during a rebuild is red.',
      '<strong>PETG black, ×2 each:</strong> clamp spine (print upright, T-head down) and clamp jaw. Two-piece so each half fits through the 21 × 11 body slot.',
      '<strong>TPU aqua (2 parts):</strong> four feet and the slit harness edge bushing — the only soft parts.',
      'Bought fasteners not shown: 4 × M3 countersunk (base), 4 × M4 + heat-sets (adapter), 4 × M4 + nuts (clamp splices), 2 × M6 thumbscrews.',
    ],
    parts: 'PETG black ×2 · PETG white ×2 (+clips) · PETG red ×10 · black clamp pair ×2 · TPU aqua ×2',
  };
  return g;
}
