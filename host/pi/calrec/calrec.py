#!/usr/bin/env python3
"""Calibration mark & snapshot recorder.

The kiosk publishes a mark ({"label": "far_up"}) on /arm/cal_mark whenever
the operator hits an extent/snapshot button in CAL MODE. This node stamps
the mark with everything measurable right now — cal channel + pulse width
(from /arm/status), commanded joint angles (from /joint_states) — grabs a
camera frame from web_video_server's snapshot endpoint, and writes:

    /captures/<utc>_<ch>_<label>.jpg   camera frame
    /captures/<utc>_<ch>_<label>.json  full context sidecar
    /captures/marks.jsonl              one-line-per-mark running log

Ack (saved basename or "error: ...") goes out on /arm/cal_mark/ack so the
UI can confirm the press. Labels are free-form; the kiosk sends far_up /
far_down / far_left / far_right / snapshot.
"""

import json
import time
import urllib.request
from pathlib import Path

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState
from std_msgs.msg import String

SNAP_URL = 'http://localhost:8080/snapshot?topic=/image_raw'
OUT = Path('/captures')


class CalRecorder(Node):
    def __init__(self):
        super().__init__('cal_recorder')
        self.status = {}
        self.positions = {}
        self.create_subscription(String, '/arm/status', self.on_status, 10)
        self.create_subscription(JointState, '/joint_states', self.on_joints, 10)
        self.create_subscription(String, '/arm/cal_mark', self.on_mark, 10)
        self.ack = self.create_publisher(String, '/arm/cal_mark/ack', 10)
        OUT.mkdir(parents=True, exist_ok=True)
        self.get_logger().info(f'recording marks to {OUT}')

    def on_status(self, msg):
        try:
            self.status = json.loads(msg.data)
        except ValueError:
            pass

    def on_joints(self, msg):
        for name, pos in zip(msg.name, msg.position):
            self.positions[name] = round(pos, 4)

    def on_mark(self, msg):
        try:
            req = json.loads(msg.data) if msg.data.startswith('{') else {}
        except ValueError:
            req = {}
        label = str(req.get('label', 'snapshot'))[:32].replace('/', '_')
        ch = self.status.get('cal_ch', -1)
        stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
        base = f'{stamp}_ch{ch}_{label}'
        record = {
            'utc': stamp,
            'label': label,
            'cal_ch': ch,
            'cal_us': self.status.get('cal_us'),
            'positions_rad': dict(self.positions),
            'status': self.status,
        }
        try:
            jpeg = urllib.request.urlopen(SNAP_URL, timeout=5).read()
            (OUT / f'{base}.jpg').write_bytes(jpeg)
            record['image'] = f'{base}.jpg'
        except Exception as e:  # camera down is not fatal; keep the numbers
            record['image'] = None
            record['image_error'] = str(e)
        (OUT / f'{base}.json').write_text(json.dumps(record, indent=2))
        with (OUT / 'marks.jsonl').open('a') as f:
            f.write(json.dumps(record) + '\n')
        self.get_logger().info(f'mark saved: {base}')
        self.ack.publish(String(data=base))


def main():
    rclpy.init()
    rclpy.spin(CalRecorder())


if __name__ == '__main__':
    main()
