// servo_driver.h — PCA9685 hardware abstraction for the 6DOF arm.
//
// This class owns all hardware I/O (I2C + PWM). The radians->microseconds
// math deliberately lives in joint_mapping.h as pure functions so it can be
// unit-tested on the host without Arduino.

#pragma once

#include <stdint.h>

#include <Adafruit_PWMServoDriver.h>

#include "joint_mapping.h"

namespace arm {

class ServoDriver {
 public:
  ServoDriver();

  // Initialize the I2C bus on the given pins and bring up the PCA9685 at
  // `i2c_address` with the given PWM frame rate (50 Hz for analog servos).
  // All 16 channels are forced OFF (no pulses) before returning, so servos
  // stay limp until explicitly commanded — no lurch on boot.
  // Returns false if the PCA9685 does not respond on the bus.
  bool begin(uint8_t i2c_address, float pwm_freq_hz, int sda_pin, int scl_pin);

  // Map `rad` through the joint's calibration (limits, direction, offset,
  // pulse clamps) and emit the resulting pulse on the joint's channel.
  void writeJointRadians(const JointConfig& joint, float rad,
                         float us_per_rad);

  // Emit a raw pulse width on a channel. The PCA9685 latches the value and
  // keeps generating the pulse train autonomously until changed.
  void writeMicroseconds(uint8_t channel, uint16_t us);

  // Stop generating pulses on one channel (servo goes limp).
  void disableChannel(uint8_t channel);

  // Stop generating pulses on all 16 channels.
  void disableAll();

 private:
  Adafruit_PWMServoDriver* pwm_;
};

}  // namespace arm
