// test_main.cpp — host-side unit tests for the pure firmware modules:
//   joint_mapping.h  (radians -> microseconds calibration math)
//   trajectory.{h,cpp} (trapezoidal-velocity profile generator)
//
// Plain assert-style C++ — no framework. Build & run with ./run_tests.sh.

#include <cmath>
#include <cstdio>
#include <vector>

#include "joint_mapping.h"
#include "trajectory.h"

static int g_failures = 0;
static int g_checks = 0;

#define CHECK(cond)                                                        \
  do {                                                                     \
    ++g_checks;                                                            \
    if (!(cond)) {                                                         \
      ++g_failures;                                                        \
      std::printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);          \
    }                                                                      \
  } while (0)

#define CHECK_NEAR(a, b, tol)                                              \
  do {                                                                     \
    ++g_checks;                                                            \
    double _a = (a), _b = (b), _t = (tol);                                 \
    if (std::fabs(_a - _b) > _t) {                                         \
      ++g_failures;                                                        \
      std::printf("FAIL %s:%d: %s (=%g) != %s (=%g) tol %g\n", __FILE__,   \
                  __LINE__, #a, _a, #b, _b, _t);                           \
    }                                                                      \
  } while (0)

static const float kPi = 3.14159265f;
static const float kUsPerRad = 2000.0f / kPi;  // MG996R: 500-2500us over pi

// ---------------------------------------------------------------------------
// joint_mapping tests
// ---------------------------------------------------------------------------
static void test_mapping_center_min_max() {
  arm::JointConfig j{0, 500, 2500, 0, +1, -kPi / 2, kPi / 2, 1.0f, 2.0f};

  // center: 0 rad -> midpoint pulse
  CHECK(arm::radiansToMicroseconds(0.0f, j, kUsPerRad) == 1500);
  // max_rad (+90 deg) -> max pulse
  CHECK_NEAR(arm::radiansToMicroseconds(kPi / 2, j, kUsPerRad), 2500, 1);
  // min_rad (-90 deg) -> min pulse
  CHECK_NEAR(arm::radiansToMicroseconds(-kPi / 2, j, kUsPerRad), 500, 1);
  // quarter throw: +45 deg -> 2000us
  CHECK_NEAR(arm::radiansToMicroseconds(kPi / 4, j, kUsPerRad), 2000, 1);
}

static void test_mapping_direction_reversal() {
  arm::JointConfig fwd{0, 500, 2500, 0, +1, -kPi / 2, kPi / 2, 1.0f, 2.0f};
  arm::JointConfig rev{0, 500, 2500, 0, -1, -kPi / 2, kPi / 2, 1.0f, 2.0f};

  // Reversed joint mirrors around the center pulse.
  CHECK_NEAR(arm::radiansToMicroseconds(kPi / 2, rev, kUsPerRad), 500, 1);
  CHECK_NEAR(arm::radiansToMicroseconds(-kPi / 2, rev, kUsPerRad), 2500, 1);
  CHECK(arm::radiansToMicroseconds(0.0f, rev, kUsPerRad) == 1500);
  // Symmetric pair: fwd(+x) == rev(-x)
  for (float x = -1.5f; x <= 1.5f; x += 0.25f) {
    CHECK(arm::radiansToMicroseconds(x, fwd, kUsPerRad) ==
          arm::radiansToMicroseconds(-x, rev, kUsPerRad));
  }
}

static void test_mapping_center_offset() {
  arm::JointConfig j{0, 500, 2500, 100, +1, -kPi / 2, kPi / 2, 1.0f, 2.0f};
  CHECK(arm::radiansToMicroseconds(0.0f, j, kUsPerRad) == 1600);

  arm::JointConfig jn{0, 500, 2500, -150, +1, -kPi / 2, kPi / 2, 1.0f, 2.0f};
  CHECK(arm::radiansToMicroseconds(0.0f, jn, kUsPerRad) == 1350);
}

static void test_mapping_clamping() {
  arm::JointConfig j{0, 500, 2500, 0, +1, -0.5f, 0.5f, 1.0f, 2.0f};

  // Angles beyond the software limits clamp to the limit's pulse.
  uint16_t at_limit = arm::radiansToMicroseconds(0.5f, j, kUsPerRad);
  CHECK(arm::radiansToMicroseconds(3.0f, j, kUsPerRad) == at_limit);
  CHECK(arm::radiansToMicroseconds(100.0f, j, kUsPerRad) == at_limit);
  uint16_t at_lo = arm::radiansToMicroseconds(-0.5f, j, kUsPerRad);
  CHECK(arm::radiansToMicroseconds(-100.0f, j, kUsPerRad) == at_lo);

  // Even with a big offset pushing past the electrical range, the pulse is
  // hard-clamped to [min_us, max_us].
  arm::JointConfig big{0, 500, 2500, 800, +1, -kPi / 2, kPi / 2, 1.0f, 2.0f};
  for (float x = -4.0f; x <= 4.0f; x += 0.1f) {
    uint16_t us = arm::radiansToMicroseconds(x, big, kUsPerRad);
    CHECK(us >= 500 && us <= 2500);
  }

  // clampToJointLimits itself
  CHECK_NEAR(arm::clampToJointLimits(9.0f, j), 0.5f, 1e-7);
  CHECK_NEAR(arm::clampToJointLimits(-9.0f, j), -0.5f, 1e-7);
  CHECK_NEAR(arm::clampToJointLimits(0.25f, j), 0.25f, 1e-7);
}

// ---------------------------------------------------------------------------
// trajectory tests
// ---------------------------------------------------------------------------
struct RunResult {
  std::vector<float> pos;  // pos[0] = start, then one entry per tick
  int ticks_to_settle = -1;
};

// Step the profile for `max_ticks` ticks (or until it settles), recording
// positions.
static RunResult run_profile(arm::TrapezoidalProfile& t, float dt,
                             int max_ticks) {
  RunResult r;
  r.pos.push_back(t.position());
  for (int k = 0; k < max_ticks; ++k) {
    r.pos.push_back(t.step(dt));
    if (t.atTarget() && r.ticks_to_settle < 0) {
      r.ticks_to_settle = k + 1;
      break;
    }
  }
  return r;
}

// Verify velocity/acceleration limits from position samples.
static void check_kinematic_limits(const RunResult& r, float dt,
                                   float max_vel, float max_acc) {
  float prev_v = 0.0f;
  for (size_t k = 1; k < r.pos.size(); ++k) {
    float v = (r.pos[k] - r.pos[k - 1]) / dt;
    CHECK(std::fabs(v) <= max_vel * 1.001f + 1e-6f);
    float a = (v - prev_v) / dt;
    CHECK(std::fabs(a) <= max_acc * 1.01f + 1e-5f);
    prev_v = v;
  }
}

static void test_traj_reaches_target() {
  arm::TrapezoidalProfile t;
  t.configure(1.0f, 2.0f);
  t.reset(0.0f);
  t.setTarget(1.0f);

  const float dt = 0.02f;
  RunResult r = run_profile(t, dt, 500);
  CHECK(r.ticks_to_settle > 0);           // settled (atTarget latched)
  CHECK_NEAR(t.position(), 1.0f, 1e-3f);  // ended on target
  CHECK(t.position() == t.target());      // exact latch
  CHECK_NEAR(t.velocity(), 0.0f, 1e-6f);

  // Ideal trapezoid time for d=1, v=1, a=2 is 1.5s (75 ticks); the discrete
  // controller should be in the same ballpark, not pathologically slow.
  CHECK(r.ticks_to_settle < 120);
}

static void test_traj_respects_limits() {
  arm::TrapezoidalProfile t;
  t.configure(1.0f, 2.0f);
  t.reset(-0.8f);
  t.setTarget(1.2f);

  const float dt = 0.02f;
  RunResult r = run_profile(t, dt, 1000);
  CHECK(r.ticks_to_settle > 0);
  check_kinematic_limits(r, dt, 1.0f, 2.0f);

  // Long move must actually hit the velocity plateau (a real trapezoid).
  float peak_v = 0.0f;
  for (size_t k = 1; k < r.pos.size(); ++k) {
    peak_v = std::max(peak_v, std::fabs(r.pos[k] - r.pos[k - 1]) / dt);
  }
  CHECK(peak_v > 0.95f);
}

static void test_traj_no_overshoot_fresh_move() {
  const float dt = 0.02f;
  // Try several distances including ones that don't reach cruise speed.
  const float targets[] = {0.005f, 0.05f, 0.3f, 1.0f, 2.5f};
  for (float target : targets) {
    arm::TrapezoidalProfile t;
    t.configure(1.0f, 2.0f);
    t.reset(0.0f);
    t.setTarget(target);
    RunResult r = run_profile(t, dt, 2000);
    CHECK(r.ticks_to_settle > 0);
    for (float p : r.pos) {
      CHECK(p <= target + 1e-5f);  // never passes the target
    }
    CHECK_NEAR(t.position(), target, 1e-3f);
  }
}

static void test_traj_retarget_no_discontinuity() {
  arm::TrapezoidalProfile t;
  t.configure(1.0f, 2.0f);
  t.reset(0.0f);
  t.setTarget(1.0f);

  const float dt = 0.02f;
  std::vector<float> pos;
  pos.push_back(t.position());

  // Run 30 ticks (mid-move, at cruise), then retarget in the opposite
  // direction — a worst-case replan.
  for (int k = 0; k < 30; ++k) {
    pos.push_back(t.step(dt));
  }
  float pos_before = t.position();
  float vel_before = t.velocity();
  CHECK(vel_before > 0.5f);  // genuinely mid-move

  t.setTarget(-0.5f);
  // Replan starts from the current interpolated state, not a snap.
  CHECK(t.position() == pos_before);

  for (int k = 0; k < 600 && !t.atTarget(); ++k) {
    pos.push_back(t.step(dt));
  }
  CHECK(t.atTarget());
  CHECK_NEAR(t.position(), -0.5f, 1e-3f);

  // Continuity + limits across the entire run, including the retarget tick.
  float prev_v = 0.0f;
  for (size_t k = 1; k < pos.size(); ++k) {
    float dp = pos[k] - pos[k - 1];
    CHECK(std::fabs(dp) <= 1.0f * dt * 1.001f + 1e-6f);  // no position jump
    float v = dp / dt;
    float a = (v - prev_v) / dt;
    CHECK(std::fabs(a) <= 2.0f * 1.01f + 1e-5f);
    prev_v = v;
  }
}

static void test_traj_retarget_same_direction() {
  // Retarget farther along the same direction mid-move: should keep cruising
  // smoothly, no dip.
  arm::TrapezoidalProfile t;
  t.configure(1.0f, 2.0f);
  t.reset(0.0f);
  t.setTarget(0.6f);

  const float dt = 0.02f;
  std::vector<float> pos;
  pos.push_back(t.position());
  for (int k = 0; k < 20; ++k) {
    pos.push_back(t.step(dt));
  }
  t.setTarget(2.0f);
  for (int k = 0; k < 800 && !t.atTarget(); ++k) {
    pos.push_back(t.step(dt));
  }
  CHECK(t.atTarget());
  CHECK_NEAR(t.position(), 2.0f, 1e-3f);
  // Monotonic the whole way (never reverses for a same-direction retarget).
  for (size_t k = 1; k < pos.size(); ++k) {
    CHECK(pos[k] + 1e-6f >= pos[k - 1]);
  }
}

static void test_traj_zero_distance() {
  arm::TrapezoidalProfile t;
  t.configure(1.0f, 2.0f);
  t.reset(0.7f);
  t.setTarget(0.7f);

  const float dt = 0.02f;
  for (int k = 0; k < 10; ++k) {
    float p = t.step(dt);
    CHECK_NEAR(p, 0.7f, 1e-6f);
  }
  CHECK(t.atTarget());
  CHECK_NEAR(t.velocity(), 0.0f, 1e-6f);
}

static void test_traj_velocity_override() {
  arm::TrapezoidalProfile t;
  t.configure(1.0f, 2.0f);
  t.reset(0.0f);
  t.setTarget(1.0f, 0.3f);  // cap this move at 0.3 rad/s

  const float dt = 0.02f;
  RunResult r = run_profile(t, dt, 2000);
  CHECK(r.ticks_to_settle > 0);
  CHECK_NEAR(t.position(), 1.0f, 1e-3f);
  check_kinematic_limits(r, dt, 0.3f, 2.0f);  // override respected

  // Override above the configured max must not raise the cap.
  arm::TrapezoidalProfile t2;
  t2.configure(1.0f, 2.0f);
  t2.reset(0.0f);
  t2.setTarget(1.0f, 99.0f);
  RunResult r2 = run_profile(t2, dt, 2000);
  CHECK(r2.ticks_to_settle > 0);
  check_kinematic_limits(r2, dt, 1.0f, 2.0f);
}

static void test_traj_negative_direction() {
  arm::TrapezoidalProfile t;
  t.configure(0.8f, 1.5f);
  t.reset(0.5f);
  t.setTarget(-1.0f);

  const float dt = 0.02f;
  RunResult r = run_profile(t, dt, 2000);
  CHECK(r.ticks_to_settle > 0);
  CHECK_NEAR(t.position(), -1.0f, 1e-3f);
  check_kinematic_limits(r, dt, 0.8f, 1.5f);
  // Never undershoots past the target.
  for (float p : r.pos) {
    CHECK(p >= -1.0f - 1e-5f);
  }
}

int main() {
  test_mapping_center_min_max();
  test_mapping_direction_reversal();
  test_mapping_center_offset();
  test_mapping_clamping();

  test_traj_reaches_target();
  test_traj_respects_limits();
  test_traj_no_overshoot_fresh_move();
  test_traj_retarget_no_discontinuity();
  test_traj_retarget_same_direction();
  test_traj_zero_distance();
  test_traj_velocity_override();
  test_traj_negative_direction();

  if (g_failures == 0) {
    std::printf("OK: %d checks passed\n", g_checks);
    return 0;
  }
  std::printf("FAILED: %d of %d checks failed\n", g_failures, g_checks);
  return 1;
}
