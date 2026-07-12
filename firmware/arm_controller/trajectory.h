// trajectory.h — per-joint trapezoidal-velocity profile generator.
//
// This module intentionally has NO Arduino dependencies (plain C++ / math.h
// only) so it can be compiled and unit-tested on the host. See
// firmware/test/ for the tests.
//
// Usage (one instance per joint):
//   TrapezoidalProfile traj;
//   traj.configure(max_vel_rad_s, max_acc_rad_s2);
//   traj.reset(initial_position);           // snap state, zero velocity
//   traj.setTarget(target_rad);             // or setTarget(rad, vel_limit)
//   float pos = traj.step(0.020f);          // call every servo tick (50 Hz)
//
// Properties (verified by host tests):
//   * |velocity| never exceeds the configured max velocity (or the per-move
//     override, whichever is lower).
//   * |acceleration| never exceeds the configured max acceleration.
//   * A fresh move (starting from rest) never overshoots its target.
//   * Retargeting mid-move replans from the current interpolated
//     position/velocity — position is always continuous (no snapping).
//   * The profile settles exactly on the target and reports atTarget().

#pragma once

namespace arm {

class TrapezoidalProfile {
 public:
  TrapezoidalProfile();

  // Set kinematic limits. Values <= 0 are coerced to a tiny positive number
  // so the profile still terminates. Call once at startup (or on reconfig).
  void configure(float max_vel, float max_acc);

  // Hard-set the internal state to `position` with zero velocity and no
  // pending motion. Used when the first command arrives for a joint whose
  // physical position is unknown (no feedback on MG996R).
  void reset(float position);

  // Command a new target position. `vel_limit_override` > 0 caps this move's
  // speed at min(override, configured max velocity); pass 0 (default) to use
  // the configured max. Safe to call at any time, including mid-move: the
  // profile replans from the current interpolated position and velocity.
  void setTarget(float target, float vel_limit_override = 0.0f);

  // Advance the profile by dt seconds and return the new position.
  // Call at a fixed rate (the firmware uses 50 Hz => dt = 0.020).
  float step(float dt);

  float position() const { return pos_; }
  float velocity() const { return vel_; }
  float target() const { return target_; }
  bool atTarget() const { return done_; }

 private:
  float effectiveVelLimit() const;

  float max_vel_;
  float max_acc_;
  float cmd_vel_limit_;  // per-move override; 0 = none
  float pos_;
  float vel_;
  float target_;
  bool done_;
};

}  // namespace arm
