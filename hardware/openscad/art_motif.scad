// =====================================================================
// art_motif.scad — the project's pixel-art motif: a robot arm rising
// from its base to grip a raspberry (leaf on top). 24 x 16 cells,
// '#' = solid material, '.' = punch hole.
//
// Shared by pi4_case.scad and electronics_spine.scad lids: the '#'
// cells become a separate full-thickness body (second filament color)
// filling a matching through-cut in a perforated lid field.
// =====================================================================

art_motif = [
    "................###.....",
    "...............##.......",
    "..............#####.....",
    ".............#######....",
    ".............#######....",
    "............#.#####.....",
    "...........###.....#....",
    "..........####..........",
    ".........###............",
    "........###.............",
    "......####..............",
    ".....###................",
    "....###.................",
    "...#######..............",
    "..#########.............",
    "..#########.............",
];
art_motif_rows = len(art_motif);
art_motif_cols = len(art_motif[0]);
