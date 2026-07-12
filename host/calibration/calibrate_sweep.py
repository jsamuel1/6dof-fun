#!/usr/bin/env python3
"""Slowly sweep one arm joint through a range for webcam-assisted calibration.

Runs INSIDE the ROS2 container (rclpy is not installed on the macOS host).
The compose file mounts this directory at /calibration in the
foxglove-bridge service, so with the stack up:

    cd host/
    docker compose exec foxglove-bridge bash -c \
      "source /opt/ros/jazzy/setup.bash && \
       python3 /calibration/calibrate_sweep.py \
         --joint 1 --from-rad -1.0 --to-rad 1.0 --step 0.1 --dwell-s 2.0"

Publishes sensor_msgs/JointState messages to /arm/joint_commands, one step
at a time, dwelling at each position so the webcam capture script
(capture_frames.py, run on the Mac host) gets several frames per position.
Progress lines are timestamped so commanded positions can be matched to
capture timestamps afterwards.

Run capture_frames.py on the host BEFORE starting the sweep.
"""

import argparse
import math
import sys
import time
from datetime import datetime

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState

VALID_JOINTS = range(1, 7)  # joint1..joint6


def ts() -> str:
    """Wall-clock timestamp, same format as capture_frames.py filenames."""
    return datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3]


def build_steps(start: float, end: float, step: float) -> list:
    """Inclusive list of positions from start to end in increments of step."""
    if step <= 0.0:
        raise ValueError("--step must be > 0")
    direction = 1.0 if end >= start else -1.0
    n = int(math.floor(abs(end - start) / step + 1e-9))
    positions = [start + direction * step * i for i in range(n + 1)]
    # Ensure the exact endpoint is hit even when the range is not an exact
    # multiple of step.
    if abs(positions[-1] - end) > 1e-9:
        positions.append(end)
    return positions


class SweepNode(Node):
    def __init__(self, topic: str):
        super().__init__("arm_calibration_sweep")
        self.pub = self.create_publisher(JointState, topic, 10)

    def send(self, joint_name: str, position: float) -> None:
        msg = JointState()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.name = [joint_name]
        msg.position = [float(position)]
        self.pub.publish(msg)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Sweep one joint through a range via /arm/joint_commands.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--joint", type=int, required=True, metavar="N",
                        help="joint number 1-6 (publishes name jointN)")
    parser.add_argument("--from-rad", dest="from_rad", type=float,
                        required=True, help="sweep start position (radians)")
    parser.add_argument("--to-rad", dest="to_rad", type=float, required=True,
                        help="sweep end position (radians)")
    parser.add_argument("--step", type=float, default=0.1,
                        help="increment per step (radians, > 0)")
    parser.add_argument("--dwell-s", dest="dwell_s", type=float, default=2.0,
                        help="seconds to hold at each position")
    parser.add_argument("--topic", default="/arm/joint_commands",
                        help="command topic")
    parser.add_argument("--settle-s", dest="settle_s", type=float, default=2.0,
                        help="extra wait after moving to the start position")
    parser.add_argument("--return-home", action="store_true",
                        help="send the joint back to 0.0 rad after the sweep")
    args = parser.parse_args()

    if args.joint not in VALID_JOINTS:
        parser.error("--joint must be 1..6")
    if args.step <= 0.0:
        parser.error("--step must be > 0")
    if args.dwell_s < 0.0:
        parser.error("--dwell-s must be >= 0")

    joint_name = f"joint{args.joint}"
    positions = build_steps(args.from_rad, args.to_rad, args.step)

    rclpy.init()
    node = SweepNode(args.topic)

    est = args.settle_s + len(positions) * args.dwell_s
    print(f"[{ts()}] sweep {joint_name}: {args.from_rad:+.3f} -> "
          f"{args.to_rad:+.3f} rad, step {args.step:.3f}, "
          f"{len(positions)} positions, dwell {args.dwell_s:.1f}s "
          f"(~{est:.0f}s total) on {args.topic}", flush=True)

    # Give DDS discovery a moment so the first message is not dropped
    # before the micro-ROS agent/firmware subscription matches.
    print(f"[{ts()}] waiting 2.0s for subscriber discovery...", flush=True)
    end = time.time() + 2.0
    while time.time() < end:
        rclpy.spin_once(node, timeout_sec=0.1)

    try:
        # Move to the start of the range and let the trajectory engine
        # finish getting there before stepping.
        node.send(joint_name, positions[0])
        print(f"[{ts()}] {joint_name} -> {positions[0]:+.3f} rad "
              f"(moving to start, settling {args.settle_s:.1f}s)", flush=True)
        time.sleep(args.settle_s)

        for i, pos in enumerate(positions, start=1):
            node.send(joint_name, pos)
            print(f"[{ts()}] {joint_name} -> {pos:+.3f} rad "
                  f"(step {i}/{len(positions)})", flush=True)
            time.sleep(args.dwell_s)

        if args.return_home:
            node.send(joint_name, 0.0)
            print(f"[{ts()}] {joint_name} -> +0.000 rad (return home)",
                  flush=True)
            time.sleep(args.settle_s)

        print(f"[{ts()}] sweep complete", flush=True)
        return 0
    except KeyboardInterrupt:
        print(f"\n[{ts()}] interrupted — arm holds its last commanded "
              f"position", flush=True)
        return 130
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    sys.exit(main())
