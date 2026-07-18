#!/bin/bash
# =====================================================================
# make_print_project.sh — rebuild hardware/arm_electronics.3mf from the
# OpenSCAD sources. Living artifact: run after any .scad change.
#
#   ./hardware/make_print_project.sh
#
# Needs: openscad (openscad@snapshot brew), BambuStudio.app, python3.
#
# One plate, 8 objects, print-ready for a P2S + AMS:
#   1  pi4 case base                      PETG slot 1 (black)
#   2  pi4 lid   (face-down, skirt up)    PETG slot 1 (black)
#   3  pi4 art: robot arm + leaf          PETG slot 2 (white)
#   4  pi4 art: raspberry                 PETG slot 3 (red)
#   5  spine body                         PETG slot 1 (black)
#   6  spine lid (face-down, skirt up)    PETG slot 1 (black)
#   7  spine art: robot arm + leaf        PETG slot 2 (white)
#   8  spine art: raspberry               PETG slot 3 (red)
# The TPU 95A feet (pi4_case.scad part="feet") are a separate job.
# =====================================================================
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCAD="$REPO/hardware/openscad"
OUT="$REPO/hardware/arm_electronics.3mf"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BAMBU=/Applications/BambuStudio.app/Contents/MacOS/BambuStudio
PROF=/Applications/BambuStudio.app/Contents/Resources/profiles/BBL
MACHINE="$PROF/machine/Bambu Lab P2S 0.4 nozzle.json"
PROCESS="$PROF/process/0.20mm Standard @BBL P2S.json"
FILAMENT="$PROF/filament/Bambu PETG Basic @BBL P2S 0.4 nozzle.json"

echo "== exporting STLs =="
# Plate placement is baked into the STLs via plate_dx/plate_dy; the
# *_plate parts also flip lids face-down so lid + art share z=0.
osc() { openscad -o "$@" 2>/dev/null; }
osc "$TMP/p1.stl" -D 'part="base"'           -D plate_dx=10  -D plate_dy=10     "$SCAD/pi4_case.scad" &
osc "$TMP/p2.stl" -D 'part="lid_plate"'      -D plate_dx=110 -D plate_dy=-127.6 "$SCAD/pi4_case.scad" &
osc "$TMP/p3.stl" -D 'part="art_arm_plate"'  -D plate_dx=110 -D plate_dy=-127.6 "$SCAD/pi4_case.scad" &
osc "$TMP/p4.stl" -D 'part="art_berry_plate"' -D plate_dx=110 -D plate_dy=-127.6 "$SCAD/pi4_case.scad" &
osc "$TMP/p5.stl" -D 'part="body"'           -D plate_dx=10  -D plate_dy=85     "$SCAD/electronics_spine.scad" &
osc "$TMP/p6.stl" -D 'part="lid_plate"'      -D plate_dx=10  -D plate_dy=53.8   "$SCAD/electronics_spine.scad" &
osc "$TMP/p7.stl" -D 'part="art_arm_plate"'  -D plate_dx=10  -D plate_dy=53.8   "$SCAD/electronics_spine.scad" &
osc "$TMP/p8.stl" -D 'part="art_berry_plate"' -D plate_dx=10 -D plate_dy=53.8   "$SCAD/electronics_spine.scad" &
wait
for i in 1 2 3 4 5 6 7 8; do
    [ -s "$TMP/p$i.stl" ] || { echo "export p$i failed" >&2; exit 1; }
done

echo "== slic3r project assembly =="
"$BAMBU" \
    --load-settings "$MACHINE;$PROCESS" \
    --load-filaments "$FILAMENT;$FILAMENT;$FILAMENT" \
    --load-filament-ids "1,1,2,3,1,1,2,3" \
    --arrange 0 \
    --export-3mf "$TMP/out.3mf" \
    "$TMP"/p1.stl "$TMP"/p2.stl "$TMP"/p3.stl "$TMP"/p4.stl \
    "$TMP"/p5.stl "$TMP"/p6.stl "$TMP"/p7.stl "$TMP"/p8.stl \
    >/dev/null

echo "== patching project settings =="
python3 - "$TMP/out.3mf" "$PROF/filament" <<'EOF'
import json, os, shutil, sys, zipfile

src, filament_dir = sys.argv[1], sys.argv[2]

# The CLI leaves most per-filament keys as single-element PLA defaults
# (filament_type ['PLA'], 45C bed temps, ...) even though the settings
# id says PETG. Resolve the real PETG preset chain and stamp every
# filament-domain key across all three slots.
def load(name):
    with open(os.path.join(filament_dir, name + ".json")) as f:
        return json.load(f)

chain, cur = [], "Bambu PETG Basic @BBL P2S 0.4 nozzle"
while cur:
    d = load(cur)
    chain.append(d)
    cur = d.get("inherits")
petg = {}
for d in reversed(chain):
    petg.update(d)

KEEP = {"filament_colour", "filament_settings_id", "filament_self_index",
        "filament_ids", "compatible_printers", "compatible_prints",
        "name", "inherits", "from", "instantiation", "setting_id"}

src_p = src + ".patched"
with zipfile.ZipFile(src) as zin, \
     zipfile.ZipFile(src_p, "w", zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == "Metadata/project_settings.config":
            cfg = json.loads(data)
            n = 0
            for k, v in petg.items():
                if k in KEEP or k not in cfg or not isinstance(v, list) or not v:
                    continue
                cfg[k] = [v[0]] * 3
                n += 1
            cfg["curr_bed_type"] = "Textured PEI Plate"
            cfg["filament_colour"] = ["#000000", "#FFFFFF", "#FF0000"]
            print(f"   stamped {n} per-filament keys as PETG x3")
            data = json.dumps(cfg, indent=4, ensure_ascii=False).encode()
        zout.writestr(item, data)
shutil.move(src_p, src)
EOF

cp "$TMP/out.3mf" "$OUT"
echo "wrote $OUT"
