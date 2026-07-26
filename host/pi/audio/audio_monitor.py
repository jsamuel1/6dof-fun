#!/usr/bin/env python3
"""Servo stall-buzz detector — BRIO mic -> /arm/audio (JSON @ ~5 Hz).

A stalled MG996R chatters against its mechanical stop at the 50 Hz servo
frame rate, dumping acoustic energy into 40-400 Hz (fundamental+harmonics)
that a quiet bench or ordinary speech doesn't. The detector:

  * captures AUDIO_DEVICE via arecord (S16_LE, 48 kHz stereo, downmixed),
  * per ~0.2 s chunk, computes band energy (40-400 Hz) vs total,
  * keeps an exponential baseline of the band level while un-buzzy,
  * flags buzz when band level jumps BUZZ_RISE_DB over baseline, exceeds
    BUZZ_MIN_DB absolute, and the band dominates the spectrum — for two
    consecutive chunks (debounce).

Topics:
  pub /arm/audio        std_msgs/String  JSON:
        {"enabled":bool,"buzz":bool,"rms_db":f,"band_db":f,
         "baseline_db":f,"band_ratio":f}
  sub /arm/audio/enable std_msgs/Bool    toggle capture (mic on/off)

Tuning env vars: AUDIO_DEVICE, BUZZ_MIN_DB, BUZZ_RISE_DB, BUZZ_RATIO.
"""

import json
import os
import subprocess
import threading

import numpy as np
import rclpy
from rclpy.node import Node
from std_msgs.msg import Bool, String

RATE = 48000
CHANNELS = 2
CHUNK = 9600                      # 0.2 s -> ~5 Hz publish rate
BAND_LO, BAND_HI = 40.0, 400.0    # stall-chatter band

DEVICE = os.environ.get('AUDIO_DEVICE', 'hw:BRIO,0')
BUZZ_MIN_DB = float(os.environ.get('BUZZ_MIN_DB', '-45'))
BUZZ_RISE_DB = float(os.environ.get('BUZZ_RISE_DB', '12'))
BUZZ_RATIO = float(os.environ.get('BUZZ_RATIO', '0.45'))
BASELINE_ALPHA = 0.02             # slow EMA: adapts in ~10 s, ignores blips


class AudioMonitor(Node):
    def __init__(self):
        super().__init__('audio_monitor')
        self.pub = self.create_publisher(String, '/arm/audio', 10)
        self.create_subscription(Bool, '/arm/audio/enable', self.on_enable, 10)
        self.enabled = True
        self.proc = None
        self.baseline_db = None
        self.buzz_streak = 0
        self.lock = threading.Lock()
        threading.Thread(target=self.capture_loop, daemon=True).start()
        self.get_logger().info(f'listening on {DEVICE}')

    def on_enable(self, msg):
        with self.lock:
            self.enabled = bool(msg.data)
            if not self.enabled and self.proc:
                self.proc.kill()
                self.proc = None
        self.get_logger().info(f'mic {"on" if msg.data else "off"}')

    def start_capture(self):
        return subprocess.Popen(
            ['arecord', '-D', DEVICE, '-f', 'S16_LE', '-r', str(RATE),
             '-c', str(CHANNELS), '-t', 'raw', '-q'],
            stdout=subprocess.PIPE)

    def publish(self, buzz, rms_db, band_db, ratio):
        base = self.baseline_db
        self.pub.publish(String(data=json.dumps({
            'enabled': self.enabled, 'buzz': buzz,
            'rms_db': round(rms_db, 1), 'band_db': round(band_db, 1),
            'baseline_db': None if base is None else round(base, 1),
            'band_ratio': round(ratio, 2)})))

    def capture_loop(self):
        window = np.hanning(CHUNK)
        freqs = np.fft.rfftfreq(CHUNK, 1.0 / RATE)
        band = (freqs >= BAND_LO) & (freqs <= BAND_HI)
        nbytes = CHUNK * CHANNELS * 2
        while True:
            with self.lock:
                enabled, proc = self.enabled, self.proc
            if not enabled:
                self.publish(False, -120.0, -120.0, 0.0)
                rclpy.spin_once(self, timeout_sec=0.5)
                continue
            if proc is None:
                with self.lock:
                    self.proc = proc = self.start_capture()
            raw = proc.stdout.read(nbytes)
            if raw is None or len(raw) < nbytes:
                with self.lock:
                    if self.proc:
                        self.proc.kill()
                        self.proc = None
                rclpy.spin_once(self, timeout_sec=1.0)
                continue
            x = np.frombuffer(raw, dtype=np.int16).astype(np.float32)
            x = x.reshape(-1, CHANNELS).mean(axis=1) / 32768.0
            rms = float(np.sqrt(np.mean(x * x))) + 1e-10
            spec = np.abs(np.fft.rfft(x * window)) ** 2
            total = float(spec.sum()) + 1e-20
            band_e = float(spec[band].sum())
            ratio = band_e / total
            rms_db = 20.0 * np.log10(rms)
            band_db = 10.0 * np.log10(band_e / CHUNK ** 2 + 1e-20)

            if self.baseline_db is None:
                self.baseline_db = band_db
            hot = (band_db > BUZZ_MIN_DB and ratio > BUZZ_RATIO and
                   band_db > self.baseline_db + BUZZ_RISE_DB)
            if hot:
                self.buzz_streak += 1
            else:
                self.buzz_streak = 0
                # only learn baseline from un-buzzy audio
                self.baseline_db += BASELINE_ALPHA * (band_db - self.baseline_db)
            buzz = self.buzz_streak >= 2
            self.publish(buzz, rms_db, band_db, ratio)
            rclpy.spin_once(self, timeout_sec=0.0)


def main():
    rclpy.init()
    node = AudioMonitor()
    try:
        # capture_loop drives spin; keep main thread parked
        threading.Event().wait()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
