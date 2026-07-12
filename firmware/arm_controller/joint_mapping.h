// joint_mapping.h — pure radians -> servo-pulse-microseconds mapping.
//
// This header intentionally has NO Arduino dependencies (plain C++ / stdint
// only) so it can be compiled and unit-tested on the host. See
// firmware/test/ for the tests. All hardware I/O lives in servo_driver.{h,cpp}.
//
// Conventions:
//   * Joint angle 0 rad == mechanical center of the servo, which is the
//     midpoint of (min_us, max_us) shifted by center_offset_us.
//   * Positive angles move toward max_us when direction == +1, toward
//     min_us when direction == -1.
//   * The electrical scale (microseconds per radian) is a property of the
//     servo model (e.g. MG996R: 2000 us over ~pi rad) and is passed in as
//     us_per_rad; per-joint trim lives in the JointConfig fields.

#pragma once

#include <stdint.h>

namespace arm {

// Per-joint calibration and limit record. One entry per joint in config.h.
struct JointConfig {
  uint8_t channel;           // PCA9685 output channel (0..15)
  uint16_t min_us;           // absolute minimum pulse ever sent (hard stop)
  uint16_t max_us;           // absolute maximum pulse ever sent (hard stop)
  int16_t center_offset_us;  // trim: shifts the 0-rad pulse from the midpoint
  int8_t direction;          // +1 or -1: flips rotation sense
  float min_rad;             // software joint limit, radians
  float max_rad;             // software joint limit, radians
  float max_vel_rad_s;       // trajectory max velocity, rad/s
  float max_acc_rad_s2;      // trajectory max acceleration, rad/s^2
};

inline float clampf(float v, float lo, float hi) {
  return (v < lo) ? lo : ((v > hi) ? hi : v);
}

// Clamp a commanded angle to the joint's software limits.
inline float clampToJointLimits(float rad, const JointConfig& j) {
  return clampf(rad, j.min_rad, j.max_rad);
}

// Center pulse for this joint (0-rad position), in microseconds.
inline float centerMicroseconds(const JointConfig& j) {
  return 0.5f * (static_cast<float>(j.min_us) + static_cast<float>(j.max_us)) +
         static_cast<float>(j.center_offset_us);
}

// Map a joint angle in radians to a pulse width in microseconds.
// Applies, in order: software joint limits, direction, center offset,
// and finally the hard min_us/max_us pulse clamp. Always returns a value
// in [min_us, max_us].
inline uint16_t radiansToMicroseconds(float rad, const JointConfig& j,
                                      float us_per_rad) {
  rad = clampToJointLimits(rad, j);
  float us = centerMicroseconds(j) +
             static_cast<float>(j.direction) * rad * us_per_rad;
  us = clampf(us, static_cast<float>(j.min_us), static_cast<float>(j.max_us));
  return static_cast<uint16_t>(us + 0.5f);  // round to nearest microsecond
}

}  // namespace arm
