#!/bin/bash
# =====================================================================
# make_boards_plate.sh — rebuild hardware/modular_boards_plate.3mf:
# the combo PCA9685 + ESP32 plate for the downloaded modular mounting
# system, merged into that system's donor project (proj.3mf).
#
#   ./hardware/make_boards_plate.sh [path/to/proj.3mf]
#
# Living artifact: run after any modular_boards_plate.scad change.
# Needs: openscad, BambuStudio.app, python3, and the donor project
# (default ~/Downloads/proj.3mf).
#
# The BambuStudio CLI has an internal race in its session-backup
# code (boost remove_all on its own backup dir -> SIGABRT, exit 134,
# output NOT written). It is flaky, not deterministic, so: clear the
# backup cache and retry until the export succeeds.
# =====================================================================
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DONOR="${1:-$HOME/Downloads/proj.3mf}"
OUT="$REPO/hardware/modular_boards_plate.3mf"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BAMBU=/Applications/BambuStudio.app/Contents/MacOS/BambuStudio

[ -f "$DONOR" ] || { echo "donor project not found: $DONOR" >&2; exit 1; }
if pgrep -xq BambuStudio; then
    echo "ERROR: quit the BambuStudio app first - its CLI is even flakier while the GUI is running." >&2
    exit 1
fi

echo "== exporting STL =="
openscad -o "$TMP/boards_plate.stl" "$REPO/hardware/openscad/modular_boards_plate.scad" 2>/dev/null
[ -s "$TMP/boards_plate.stl" ] || { echo "STL export failed" >&2; exit 1; }

echo "== merging into donor project (with backup-race retries) =="
ok=0
for attempt in 1 2 3 4 5 6 7 8; do
    rm -rf "$(getconf DARWIN_USER_TEMP_DIR)/bamboo_model"
    if "$BAMBU" --arrange 1 --export-3mf "$TMP/out.3mf" \
            "$DONOR" "$TMP/boards_plate.stl" >"$TMP/merge.log" 2>&1 \
       && [ -s "$TMP/out.3mf" ]; then
        ok=1
        echo "   merged on attempt $attempt"
        break
    fi
    echo "   attempt $attempt hit the backup race, retrying"
done
[ "$ok" = 1 ] || { echo "merge failed 8 times; last log:" >&2; tail -5 "$TMP/merge.log" >&2; exit 1; }

echo "== forcing by-layer print sequence =="
python3 - "$TMP/out.3mf" <<'EOF'
import json, shutil, sys, zipfile
src = sys.argv[1]
with zipfile.ZipFile(src) as zin, zipfile.ZipFile(src + ".p", "w", zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == "Metadata/project_settings.config":
            cfg = json.loads(data)
            cfg["print_sequence"] = "by layer"
            data = json.dumps(cfg, indent=4, ensure_ascii=False).encode()
        zout.writestr(item, data)
shutil.move(src + ".p", src)
EOF

cp "$TMP/out.3mf" "$OUT"
echo "wrote $OUT"
