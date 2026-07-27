#!/bin/bash
# =====================================================================
# make_keel_fitcheck.sh — build hardware/keel_jct_fitcheck.3mf: the
# junction-tray fit-check plate (tray crop + comb + latch bar + lid),
# single PETG filament, P2S textured plate.
#
#   ./hardware/make_keel_fitcheck.sh
# =====================================================================
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/hardware/keel_jct_fitcheck.3mf"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BAMBU=/Applications/BambuStudio.app/Contents/MacOS/BambuStudio
PROF=/Applications/BambuStudio.app/Contents/Resources/profiles/BBL
MACHINE="$PROF/machine/Bambu Lab P2S 0.4 nozzle.json"
PROCESS="$PROF/process/0.20mm Standard @BBL P2S.json"
FILAMENT="$PROF/filament/Bambu PETG Basic @BBL P2S 0.4 nozzle.json"

echo "== exporting STL =="
openscad -o "$TMP/plate.stl" -D 'fpart="plate"' \
    "$REPO/hardware/openscad/keel_fitcheck_jct.scad" 2>/dev/null
[ -s "$TMP/plate.stl" ] || { echo "export failed" >&2; exit 1; }

echo "== slic3r project assembly =="
"$BAMBU" \
    --load-settings "$MACHINE;$PROCESS" \
    --load-filaments "$FILAMENT" \
    --arrange 0 \
    --export-3mf "$TMP/out.3mf" \
    "$TMP/plate.stl" >/dev/null

echo "== patching project settings =="
python3 - "$TMP/out.3mf" "$PROF/filament" <<'EOF'
import json, os, shutil, sys, zipfile

src, filament_dir = sys.argv[1], sys.argv[2]

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
            n = len(cfg.get("filament_colour", ["1"]))
            for k, v in petg.items():
                if k in KEEP or k not in cfg or not isinstance(v, list) or not v:
                    continue
                cfg[k] = [v[0]] * n
            cfg["curr_bed_type"] = "Textured PEI Plate"
            data = json.dumps(cfg, indent=4, ensure_ascii=False).encode()
        zout.writestr(item, data)
shutil.move(src_p, src)
EOF

cp "$TMP/out.3mf" "$OUT"
echo "wrote $OUT"
