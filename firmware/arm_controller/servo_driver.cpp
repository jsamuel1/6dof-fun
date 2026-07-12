// servo_driver.cpp — PCA9685 hardware I/O implementation.

#include "servo_driver.h"

#include <Wire.h>

namespace arm {

namespace {
// Nominal PCA9685 internal oscillator. The datasheet says 25 MHz but real
// boards typically run fast; 27 MHz gives measurably more accurate pulse
// widths on common breakouts (Adafruit's own recommendation). If calibration
// shows a constant scale error on ALL joints, tune this value first.
constexpr uint32_t kOscillatorHz = 27000000;
}  // namespace

ServoDriver::ServoDriver() : pwm_(nullptr) {}

bool ServoDriver::begin(uint8_t i2c_address, float pwm_freq_hz, int sda_pin,
                        int scl_pin) {
  Wire.begin(sda_pin, scl_pin);
  Wire.setClock(400000);  // PCA9685 supports fast-mode I2C

  if (pwm_ != nullptr) {
    delete pwm_;
    pwm_ = nullptr;
  }
  pwm_ = new Adafruit_PWMServoDriver(i2c_address, Wire);

  if (!pwm_->begin()) {
    delete pwm_;
    pwm_ = nullptr;
    return false;
  }
  pwm_->setOscillatorFrequency(kOscillatorHz);
  pwm_->setPWMFreq(pwm_freq_hz);

  // Safety: no pulses on any channel until the first valid command.
  disableAll();
  return true;
}

void ServoDriver::writeJointRadians(const JointConfig& joint, float rad,
                                    float us_per_rad) {
  writeMicroseconds(joint.channel, radiansToMicroseconds(rad, joint, us_per_rad));
}

void ServoDriver::writeMicroseconds(uint8_t channel, uint16_t us) {
  if (pwm_ == nullptr) {
    return;
  }
  pwm_->writeMicroseconds(channel, us);
}

void ServoDriver::disableChannel(uint8_t channel) {
  if (pwm_ == nullptr) {
    return;
  }
  // setPWM with the full-OFF bit (bit 12 of the OFF register) stops the
  // pulse train entirely on this channel.
  pwm_->setPWM(channel, 0, 4096);
}

void ServoDriver::disableAll() {
  for (uint8_t ch = 0; ch < 16; ++ch) {
    disableChannel(ch);
  }
}

}  // namespace arm
