// trajectory.cpp — trapezoidal-velocity profile implementation.
// No Arduino dependencies; compiled both for the ESP32 and for host tests.

#include "trajectory.h"

#include <math.h>

namespace arm {

namespace {
// Snap window: once we are within this many radians of the target AND nearly
// stopped, we latch exactly onto the target. 1e-4 rad ~= 0.006 degrees —
// far below MG996R resolution.
constexpr float kSnapPosEps = 1e-4f;
// Floor for limits so a mis-configured 0/negative limit cannot stall or
// divide-by-zero the profile.
constexpr float kMinLimit = 1e-6f;
}  // namespace

TrapezoidalProfile::TrapezoidalProfile()
    : max_vel_(1.0f),
      max_acc_(1.0f),
      cmd_vel_limit_(0.0f),
      pos_(0.0f),
      vel_(0.0f),
      target_(0.0f),
      done_(true) {}

void TrapezoidalProfile::configure(float max_vel, float max_acc) {
  max_vel_ = (max_vel > kMinLimit) ? max_vel : kMinLimit;
  max_acc_ = (max_acc > kMinLimit) ? max_acc : kMinLimit;
}

void TrapezoidalProfile::reset(float position) {
  pos_ = position;
  vel_ = 0.0f;
  target_ = position;
  cmd_vel_limit_ = 0.0f;
  done_ = true;
}

void TrapezoidalProfile::setTarget(float target, float vel_limit_override) {
  target_ = target;
  cmd_vel_limit_ = (vel_limit_override > 0.0f) ? vel_limit_override : 0.0f;
  done_ = false;  // step() latches done_ again once we settle on the target
}

float TrapezoidalProfile::effectiveVelLimit() const {
  if (cmd_vel_limit_ > 0.0f && cmd_vel_limit_ < max_vel_) {
    return cmd_vel_limit_;
  }
  return max_vel_;
}

float TrapezoidalProfile::step(float dt) {
  if (dt <= 0.0f || done_) {
    return pos_;
  }

  const float vmax = effectiveVelLimit();
  const float a = max_acc_;
  const float dist = target_ - pos_;
  const float adist = fabsf(dist);

  // Latch exactly onto the target once close and nearly stopped. The
  // velocity change here is at most a*dt, so the acceleration limit holds
  // across the snap as well.
  if (adist <= kSnapPosEps && fabsf(vel_) <= a * dt) {
    pos_ = target_;
    vel_ = 0.0f;
    done_ = true;
    return pos_;
  }

  const float s = (dist >= 0.0f) ? 1.0f : -1.0f;

  // Discrete-time-safe stopping bound: the largest speed v such that moving
  // for one tick at v and then decelerating at a stays within `adist`:
  //     v*dt + v^2 / (2a) <= adist
  // Solving for v gives the positive root below. Using this (instead of the
  // continuous sqrt(2*a*d)) prevents overshoot/limit-cycling at a fixed
  // update rate.
  const float vbound = a * (sqrtf(dt * dt + 2.0f * adist / a) - dt);
  const float vdes = s * ((vmax < vbound) ? vmax : vbound);

  // Accelerate toward the desired velocity, limited to a*dt per tick.
  float dv = vdes - vel_;
  const float max_dv = a * dt;
  if (dv > max_dv) {
    dv = max_dv;
  } else if (dv < -max_dv) {
    dv = -max_dv;
  }
  vel_ += dv;
  pos_ += vel_ * dt;
  return pos_;
}

}  // namespace arm
