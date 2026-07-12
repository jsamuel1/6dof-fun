#!/usr/bin/env python3
"""Capture timestamped webcam frames during a calibration sweep.

Runs ON the Mac host (NOT in Docker — containers cannot access the Mac
webcam). Pure OpenCV, no ROS dependencies:

    cd host/calibration
    python3 -m venv .venv && source .venv/bin/activate   # first time
    pip install -r requirements.txt                       # first time
    python3 capture_frames.py --interval-s 0.5

Frames are written to captures/ (created if missing) with wall-clock
timestamps in the filenames, e.g.:

    captures/frame_2026-07-12T14-03-27.512.jpg

calibrate_sweep.py prints the same wall-clock timestamps for each commanded
position, so frames can be matched to commands afterwards.

Stop with Ctrl-C. macOS will prompt for camera permission on first run
(grant it to your terminal app).
"""

import argparse
import os
import sys
import time
from datetime import datetime

try:
    import cv2
except ImportError:
    print("OpenCV not found. Install with: pip install -r requirements.txt",
          file=sys.stderr)
    sys.exit(1)


def ts_for_filename() -> str:
    # Colons are avoided in filenames; keep lexicographic == chronological.
    return datetime.now().strftime("%Y-%m-%dT%H-%M-%S.%f")[:-3]


def ts_for_log() -> str:
    return datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Capture timestamped webcam frames into captures/.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--device", type=int, default=0,
                        help="camera index (0 = built-in Mac camera)")
    parser.add_argument("--interval-s", dest="interval_s", type=float,
                        default=1.0, help="seconds between captured frames")
    parser.add_argument("--duration-s", dest="duration_s", type=float,
                        default=0.0,
                        help="stop after this many seconds (0 = until Ctrl-C)")
    parser.add_argument("--outdir", default="captures",
                        help="output directory for frames")
    parser.add_argument("--width", type=int, default=0,
                        help="requested capture width (0 = camera default)")
    parser.add_argument("--height", type=int, default=0,
                        help="requested capture height (0 = camera default)")
    parser.add_argument("--prefix", default="frame",
                        help="filename prefix (use e.g. joint3 per sweep)")
    args = parser.parse_args()

    if args.interval_s <= 0:
        parser.error("--interval-s must be > 0")

    os.makedirs(args.outdir, exist_ok=True)

    print(f"[{ts_for_log()}] opening camera {args.device}...", flush=True)
    cap = cv2.VideoCapture(args.device)
    if not cap.isOpened():
        print(f"[{ts_for_log()}] ERROR: cannot open camera {args.device}. "
              f"Check macOS camera permissions for your terminal, or try "
              f"another --device index.", file=sys.stderr)
        return 1

    if args.width > 0:
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
    if args.height > 0:
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)

    # Warm up: first frames from Mac cameras are often dark/empty.
    for _ in range(5):
        cap.read()

    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    print(f"[{ts_for_log()}] capturing {w}x{h} every {args.interval_s}s "
          f"into {args.outdir}/ — Ctrl-C to stop", flush=True)

    count = 0
    start = time.time()
    try:
        while True:
            if args.duration_s > 0 and time.time() - start >= args.duration_s:
                break
            loop_start = time.time()

            # Drain buffered frames so the saved frame is current, not stale.
            cap.grab()
            ok, frame = cap.read()
            if not ok or frame is None:
                print(f"[{ts_for_log()}] WARNING: frame grab failed, "
                      f"retrying", file=sys.stderr)
                time.sleep(args.interval_s)
                continue

            fname = f"{args.prefix}_{ts_for_filename()}.jpg"
            path = os.path.join(args.outdir, fname)
            if not cv2.imwrite(path, frame):
                print(f"[{ts_for_log()}] ERROR: failed to write {path}",
                      file=sys.stderr)
                return 1
            count += 1
            print(f"[{ts_for_log()}] saved {path} ({count} total)",
                  flush=True)

            sleep_for = args.interval_s - (time.time() - loop_start)
            if sleep_for > 0:
                time.sleep(sleep_for)
    except KeyboardInterrupt:
        pass
    finally:
        cap.release()

    print(f"\n[{ts_for_log()}] done — {count} frames in {args.outdir}/",
          flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
