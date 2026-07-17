// =====================================================================
// art_motif.scad — the project's pixel-art motif: a robot arm rising
// from its base to grip a raspberry. 24 x 16 cells.
//
//   '.' = punch hole (lid colour shows through the field)
//   'A' = arm group  (robot arm, pedestal, gripper, leaf) — filament 2
//   'B' = berry      (the raspberry)                      — filament 3
//
// Both groups become separate full-thickness bodies filling a shared
// through-cut in the perforated lid. Intended palette: black lid,
// white arm, red raspberry. Shared by pi4_case.scad and
// electronics_spine.scad.
// =====================================================================

art_motif = [
    "................AAA.....",
    "...............AA.......",
    "..............BBBBB.....",
    ".............BBBBBBB....",
    ".............BBBBBBB....",
    "............A.BBBBB.....",
    "...........AAA.....A....",
    "..........AAAA..........",
    ".........AAA............",
    "........AAA.............",
    "......AAAA..............",
    ".....AAA................",
    "....AAA.................",
    "...AAAAAAA..............",
    "..AAAAAAAAA.............",
    "..AAAAAAAAA.............",
];
art_motif_rows = len(art_motif);
art_motif_cols = len(art_motif[0]);
