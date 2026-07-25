// config.example.h — TEMPLATE configuration for the 6DOF arm controller.
//
//   1. Copy this file to config.h (same directory).
//   2. Fill in your WiFi credentials and the micro-ROS agent IP.
//   3. Refine the per-joint calibration table as you calibrate each joint.
//
// config.h is gitignored so real credentials are never committed; this
// template is the committed reference. Every field is documented below.

#pragma once

#include "joint_mapping.h"

// ---------------------------------------------------------------------------
// WiFi — the ESP32 joins this network to reach the micro-ROS agent.
// ---------------------------------------------------------------------------
#define WIFI_SSID "your-wifi-ssid"          // 2.4 GHz network (ESP32 has no 5 GHz)
#define WIFI_PASSWORD "your-wifi-password"  // WPA2 passphrase

// ---------------------------------------------------------------------------
// micro-ROS agent — the host running `micro-ros-agent udp4 --port 8888`
// (see host/docker-compose.yml). When migrating between hosts, this IP is
// the only value that changes.
// ---------------------------------------------------------------------------
#define AGENT_IP "192.168.1.100"  // IPv4 address of the Docker host
#define AGENT_PORT 8888           // UDP port of the micro-ROS agent (default)

// ---------------------------------------------------------------------------
// Over-the-air update password (ArduinoOTA, port 3232). After the first USB
// flash, update wirelessly with:
//   arduino-cli upload --fqbn esp32:esp32:esp32 -p <esp32-ip> \
//     --upload-field password=<this value> firmware/arm_controller
// OTA reboots into the new image with all joints disarmed (arm goes limp) —
// flash only with the arm supported or servo power off.
// ---------------------------------------------------------------------------
#define OTA_PASSWORD "change-me"

// ---------------------------------------------------------------------------
// I2C bus to the PCA9685 servo driver board.
// ---------------------------------------------------------------------------
#define I2C_SDA_PIN 21           // ESP32 default SDA (GPIO21)
#define I2C_SCL_PIN 22           // ESP32 default SCL (GPIO22)
#define PCA9685_I2C_ADDRESS 0x40 // default address, all address jumpers open
#define SERVO_PWM_FREQ_HZ 50.0f  // standard analog-servo frame rate (20 ms)

// ---------------------------------------------------------------------------
// Servo electrical scale.
// MG996R: ~2000 us of pulse span (500..2500 us) sweeps ~180 deg (pi rad),
// so us-per-radian = 2000 / pi. Shared by all six joints; per-joint trim
// (offset, direction, pulse clamps) lives in the table below.
// ---------------------------------------------------------------------------
#define SERVO_US_PER_RAD 636.6198f  // = (2500 - 500) / pi

// ---------------------------------------------------------------------------
// Per-joint calibration table (joint1..joint6 == channels 0..5).
//
// Field reference (see arm::JointConfig in joint_mapping.h):
//   channel           PCA9685 output the servo signal wire is plugged into.
//   min_us            Hard minimum pulse ever sent, microseconds. Raise this
//                     above 500 if the joint hits a mechanical stop early.
//   max_us            Hard maximum pulse ever sent, microseconds. Lower this
//                     below 2500 if the joint hits a mechanical stop early.
//   center_offset_us  Trim added to the (min_us+max_us)/2 midpoint so that a
//                     command of 0 rad puts the link at its true mechanical
//                     center. Found during webcam-assisted calibration.
//   direction         +1 or -1. Flip so that positive radians follow the
//                     arm's kinematic convention (counter-clockwise positive
//                     when viewed down each joint axis).
//   min_rad, max_rad  SOFTWARE joint limits, radians. Every command is
//                     clamped to this range before execution. Start narrow,
//                     widen after verifying clearances on real hardware.
//   max_vel_rad_s     Trajectory speed limit, rad/s. 1.0 rad/s (~57 deg/s)
//                     is a conservative bring-up value for MG996R.
//   max_acc_rad_s2    Trajectory acceleration limit, rad/s^2. 2.0 keeps
//                     current spikes gentle on the 6 V rail.
//
// Defaults below are safe bring-up values: full 500-2500 us electrical
// range, +/- 90 deg software limits, slow and gentle motion. Tighten after
// calibration (bring-up sequence step 3 in the design doc).
// ---------------------------------------------------------------------------
#define NUM_JOINTS 6

static const arm::JointConfig JOINT_CONFIG[NUM_JOINTS] = {
    // ch, min_us, max_us, off,  dir, min_rad,  max_rad,  vel,  acc
    {0, 500, 2500, 0, +1, -1.5708f, 1.5708f, 1.0f, 2.0f},  // joint1: base yaw
    {1, 500, 2500, 0, +1, -1.5708f, 1.5708f, 1.0f, 2.0f},  // joint2: shoulder
    {2, 500, 2500, 0, +1, -1.5708f, 1.5708f, 1.0f, 2.0f},  // joint3: elbow
    {3, 500, 2500, 0, +1, -1.5708f, 1.5708f, 1.0f, 2.0f},  // joint4: wrist pitch
    {4, 500, 2500, 0, +1, -1.5708f, 1.5708f, 1.0f, 2.0f},  // joint5: wrist roll
    {5, 500, 2500, 0, +1, -1.5708f, 1.5708f, 1.0f, 2.0f},  // joint6: gripper
};
