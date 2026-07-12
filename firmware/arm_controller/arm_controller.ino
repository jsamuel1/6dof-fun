// arm_controller.ino — 6DOF robot arm micro-ROS firmware for ESP32.
//
// ROS2 interface (node "arm_controller", micro-ROS over WiFi/UDP):
//   pub  /joint_states       sensor_msgs/JointState  @ 20 Hz (commanded angles)
//   pub  /arm/status         std_msgs/String (JSON)  @ 1 Hz
//   sub  /arm/joint_commands sensor_msgs/JointState  (position targets, rad;
//                            velocity[] optionally caps per-joint speed)
//
// Control behavior:
//   * 50 Hz servo update loop driven by millis(), fully decoupled from ROS
//     message arrival — commands only retarget the trajectory generators.
//     Missed periods (blocking agent pings / reconnects) are caught up with
//     extra fixed-dt steps so in-flight motion keeps wall-clock timing.
//   * Servos emit NO pulses until the first valid command arrives for that
//     joint (no lurch on boot; MG996R has no position feedback).
//   * Software joint limits clamp every command before execution.
//   * Agent link watchdog: connection state machine WAITING_AGENT ->
//     AGENT_AVAILABLE -> AGENT_CONNECTED -> AGENT_DISCONNECTED. If the agent
//     is unreachable for > 2 s the entities are destroyed and re-created
//     automatically; throughout, servos HOLD the last commanded position
//     (the PCA9685 keeps generating the last pulse train; we never disable
//     channels on link loss — a limp arm would fall).
//
// Requires: config.h (copy config.example.h and edit), micro_ros_arduino
// (Jazzy), Adafruit PWM Servo Driver Library. See firmware/README.md.

#include "config.h"
#include "joint_mapping.h"
#include "servo_driver.h"
#include "trajectory.h"

#include <micro_ros_arduino.h>

#include <rcl/rcl.h>
#include <rcl/error_handling.h>
#include <rclc/rclc.h>
#include <rclc/executor.h>
#include <rmw_microros/rmw_microros.h>

#include <sensor_msgs/msg/joint_state.h>
#include <std_msgs/msg/string.h>
#include <rosidl_runtime_c/string_functions.h>
#include <rosidl_runtime_c/primitives_sequence_functions.h>

#include <WiFi.h>

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ---------------------------------------------------------------------------
// Timing constants
// ---------------------------------------------------------------------------
static const uint32_t SERVO_PERIOD_MS = 20;        // 50 Hz servo loop
static const float SERVO_DT_S = 0.020f;
// If a loop() iteration is delayed (agent pings while disconnected, entity
// re-creation, WiFi hiccups), the servo loop catches up by running one
// fixed-dt trajectory step per missed period, so in-flight motion stays on
// wall-clock time at the profiled velocity. Catch-up is capped; anything
// older is dropped, which only ever makes motion slower (the safe direction).
static const uint32_t MAX_CATCHUP_STEPS = 50;      // = 1 s of missed periods
static const uint32_t JOINT_STATE_PERIOD_MS = 50;  // 20 Hz /joint_states
static const uint32_t STATUS_PERIOD_MS = 1000;     // 1 Hz /arm/status
static const uint32_t PING_PERIOD_MS = 500;        // agent liveness probe
static const uint32_t PING_TIMEOUT_MS = 100;       // per-probe timeout
static const uint32_t AGENT_TIMEOUT_MS = 2000;     // link considered lost

// ---------------------------------------------------------------------------
// Connection state machine
// ---------------------------------------------------------------------------
enum AgentState {
  WAITING_AGENT,      // no agent seen yet; probing
  AGENT_AVAILABLE,    // agent answered a ping; create entities
  AGENT_CONNECTED,    // entities live; publishing/subscribing
  AGENT_DISCONNECTED  // link lost; tear down and go back to WAITING_AGENT
};

static AgentState agent_state = WAITING_AGENT;

// ---------------------------------------------------------------------------
// micro-ROS entities
// ---------------------------------------------------------------------------
static rcl_allocator_t allocator;
static rclc_support_t support;
static rcl_node_t node;
static rcl_publisher_t pub_joint_states;
static rcl_publisher_t pub_status;
static rcl_subscription_t sub_commands;
static rclc_executor_t executor;

static sensor_msgs__msg__JointState joint_state_msg;  // outgoing
static sensor_msgs__msg__JointState cmd_msg;          // incoming buffer
static std_msgs__msg__String status_msg;              // outgoing

static const char* const kJointNames[NUM_JOINTS] = {
    "joint1", "joint2", "joint3", "joint4", "joint5", "joint6"};

// ---------------------------------------------------------------------------
// Motion state
// ---------------------------------------------------------------------------
static arm::ServoDriver servo;
static arm::TrapezoidalProfile traj[NUM_JOINTS];
// A joint emits pulses only after its first valid command ("armed").
static bool joint_armed[NUM_JOINTS] = {false};
static bool pca9685_ok = false;
static bool estop = false;  // reserved: no e-stop input in phase-1 hardware

// ---------------------------------------------------------------------------
// Timers / bookkeeping
// ---------------------------------------------------------------------------
static uint32_t last_servo_ms = 0;
static uint32_t last_joint_state_ms = 0;
static uint32_t last_status_ms = 0;
static uint32_t last_ping_ms = 0;
static uint32_t last_agent_ok_ms = 0;
static char status_buf[192];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
#define RCFAIL_RETURN_FALSE(fn)   \
  do {                            \
    if ((fn) != RCL_RET_OK) {     \
      return false;               \
    }                             \
  } while (0)

// Grow a rosidl string's buffer so incoming (deserialized) data fits.
static void reserve_string(rosidl_runtime_c__String* s, size_t cap) {
  char* grown = (char*)realloc(s->data, cap);
  if (grown == NULL) {
    return;  // keep old buffer; deserialization of long names may fail
  }
  s->data = grown;
  s->data[0] = '\0';
  s->size = 0;
  s->capacity = cap;
}

static int joint_index_from_name(const char* name) {
  for (int i = 0; i < NUM_JOINTS; ++i) {
    if (strcmp(name, kJointNames[i]) == 0) {
      return i;
    }
  }
  return -1;
}

static void stamp_now(builtin_interfaces__msg__Time* stamp) {
  if (rmw_uros_epoch_synchronized()) {
    int64_t ms = rmw_uros_epoch_millis();
    stamp->sec = (int32_t)(ms / 1000);
    stamp->nanosec = (uint32_t)((ms % 1000) * 1000000LL);
  } else {
    uint32_t ms = millis();
    stamp->sec = (int32_t)(ms / 1000);
    stamp->nanosec = (uint32_t)((ms % 1000) * 1000000UL);
  }
}

// ---------------------------------------------------------------------------
// Message memory (allocated once in setup, reused forever)
// ---------------------------------------------------------------------------
static void init_messages() {
  // Outgoing /joint_states: fixed names, 6 positions, 6 velocities.
  sensor_msgs__msg__JointState__init(&joint_state_msg);
  rosidl_runtime_c__String__assign(&joint_state_msg.header.frame_id, "");
  rosidl_runtime_c__String__Sequence__init(&joint_state_msg.name, NUM_JOINTS);
  for (int i = 0; i < NUM_JOINTS; ++i) {
    rosidl_runtime_c__String__assign(&joint_state_msg.name.data[i],
                                     kJointNames[i]);
  }
  rosidl_runtime_c__double__Sequence__init(&joint_state_msg.position,
                                           NUM_JOINTS);
  rosidl_runtime_c__double__Sequence__init(&joint_state_msg.velocity,
                                           NUM_JOINTS);
  // effort left empty (size 0)

  // Incoming /arm/joint_commands: pre-allocate capacity for deserialization.
  sensor_msgs__msg__JointState__init(&cmd_msg);
  reserve_string(&cmd_msg.header.frame_id, 32);
  rosidl_runtime_c__String__Sequence__init(&cmd_msg.name, NUM_JOINTS);
  for (int i = 0; i < NUM_JOINTS; ++i) {
    reserve_string(&cmd_msg.name.data[i], 32);
  }
  rosidl_runtime_c__double__Sequence__init(&cmd_msg.position, NUM_JOINTS);
  rosidl_runtime_c__double__Sequence__init(&cmd_msg.velocity, NUM_JOINTS);
  rosidl_runtime_c__double__Sequence__init(&cmd_msg.effort, NUM_JOINTS);

  // Outgoing /arm/status: static buffer, never freed.
  std_msgs__msg__String__init(&status_msg);
  status_msg.data.data = status_buf;
  status_msg.data.size = 0;
  status_msg.data.capacity = sizeof(status_buf);
}

// ---------------------------------------------------------------------------
// Command subscription callback (runs from rclc_executor_spin_some)
// ---------------------------------------------------------------------------
static void cmd_callback(const void* msgin) {
  const sensor_msgs__msg__JointState* m =
      (const sensor_msgs__msg__JointState*)msgin;

  const size_t n = m->position.size;
  for (size_t k = 0; k < n; ++k) {
    // Resolve which joint this entry addresses: by name when provided,
    // otherwise positionally (entry k -> joint k).
    int idx = -1;
    if (k < m->name.size && m->name.data[k].data != NULL &&
        m->name.data[k].size > 0) {
      idx = joint_index_from_name(m->name.data[k].data);
    } else if (k < (size_t)NUM_JOINTS) {
      idx = (int)k;
    }
    if (idx < 0 || idx >= NUM_JOINTS) {
      continue;  // unknown joint name — ignore this entry
    }

    // Software joint limits clamp every command before execution.
    float target =
        arm::clampToJointLimits((float)m->position.data[k], JOINT_CONFIG[idx]);

    // Optional per-joint max-speed override (rad/s) via the velocity array.
    float vel_override = 0.0f;
    if (k < m->velocity.size) {
      vel_override = fabsf((float)m->velocity.data[k]);
    }

    if (!joint_armed[idx]) {
      // First command for this joint: we have no feedback, so adopt the
      // target as the current position and start emitting pulses. The servo
      // moves there at its own (uncontrolled) speed — send a first command
      // near the physical pose (see README).
      traj[idx].reset(target);
      joint_armed[idx] = true;
    } else {
      traj[idx].setTarget(target, vel_override);
    }
  }
}

// ---------------------------------------------------------------------------
// Entity lifecycle
// ---------------------------------------------------------------------------
static bool create_entities() {
  allocator = rcl_get_default_allocator();

  RCFAIL_RETURN_FALSE(rclc_support_init(&support, 0, NULL, &allocator));
  RCFAIL_RETURN_FALSE(
      rclc_node_init_default(&node, "arm_controller", "", &support));

  // /joint_states at 20 Hz: best-effort keeps a lossy WiFi link from
  // stalling the publisher; subscribers treat it as a live signal anyway.
  RCFAIL_RETURN_FALSE(rclc_publisher_init_best_effort(
      &pub_joint_states, &node,
      ROSIDL_GET_MSG_TYPE_SUPPORT(sensor_msgs, msg, JointState),
      "/joint_states"));

  RCFAIL_RETURN_FALSE(rclc_publisher_init_default(
      &pub_status, &node, ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, String),
      "/arm/status"));

  RCFAIL_RETURN_FALSE(rclc_subscription_init_default(
      &sub_commands, &node,
      ROSIDL_GET_MSG_TYPE_SUPPORT(sensor_msgs, msg, JointState),
      "/arm/joint_commands"));

  RCFAIL_RETURN_FALSE(
      rclc_executor_init(&executor, &support.context, 1, &allocator));
  RCFAIL_RETURN_FALSE(rclc_executor_add_subscription(
      &executor, &sub_commands, &cmd_msg, &cmd_callback, ON_NEW_DATA));

  // Best effort; timestamps fall back to millis() if this fails.
  (void)rmw_uros_sync_session(1000);
  return true;
}

static void destroy_entities() {
  rmw_context_t* rmw_context = rcl_context_get_rmw_context(&support.context);
  (void)rmw_uros_set_context_entity_destroy_session_timeout(rmw_context, 0);

  (void)rclc_executor_fini(&executor);
  (void)rcl_subscription_fini(&sub_commands, &node);
  (void)rcl_publisher_fini(&pub_joint_states, &node);
  (void)rcl_publisher_fini(&pub_status, &node);
  (void)rcl_node_fini(&node);
  (void)rclc_support_fini(&support);
}

// ---------------------------------------------------------------------------
// Publishing
// ---------------------------------------------------------------------------
static void publish_joint_states() {
  stamp_now(&joint_state_msg.header.stamp);
  for (int i = 0; i < NUM_JOINTS; ++i) {
    // Commanded (interpolated) angle; MG996R has no feedback. Joints that
    // have not been commanded yet report 0.0 by convention.
    joint_state_msg.position.data[i] = (double)traj[i].position();
    joint_state_msg.velocity.data[i] = (double)traj[i].velocity();
  }
  (void)rcl_publish(&pub_joint_states, &joint_state_msg, NULL);
}

static void publish_status() {
  const bool connected = (agent_state == AGENT_CONNECTED);
  int written = snprintf(
      status_buf, sizeof(status_buf),
      "{\"uptime_s\":%lu,\"rssi\":%d,\"agent_connected\":%s,\"estop\":%s}",
      (unsigned long)(millis() / 1000UL), (int)WiFi.RSSI(),
      connected ? "true" : "false", estop ? "true" : "false");
  if (written < 0) {
    return;
  }
  status_msg.data.size =
      ((size_t)written < sizeof(status_buf)) ? (size_t)written
                                             : sizeof(status_buf) - 1;
  (void)rcl_publish(&pub_status, &status_msg, NULL);
}

// ---------------------------------------------------------------------------
// Servo update loop — 50 Hz, always runs regardless of agent state.
// On link loss the trajectories simply stop receiving new targets, so each
// joint glides to (or holds) its last target and the PCA9685 keeps emitting
// the last pulse train: HOLD, never limp.
//
// `steps` is the number of fixed-dt trajectory steps to advance (normally 1;
// more when loop() was delayed by blocking micro-ROS calls). Trajectories are
// stepped `steps` times so profiled motion tracks wall-clock time, but each
// servo is written only once, at the final position.
// ---------------------------------------------------------------------------
static void servo_update(uint32_t steps) {
  for (int i = 0; i < NUM_JOINTS; ++i) {
    if (!joint_armed[i]) {
      continue;  // no pulses until the first valid command
    }
    float pos = traj[i].position();
    for (uint32_t s = 0; s < steps; ++s) {
      pos = traj[i].step(SERVO_DT_S);
    }
    servo.writeJointRadians(JOINT_CONFIG[i], pos, SERVO_US_PER_RAD);
  }
}

// ---------------------------------------------------------------------------
// setup / loop
// ---------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(1500);  // give the USB monitor a moment to attach
  Serial.println();
  Serial.println("[arm] 6DOF arm controller booting");

  // Trajectory generators (limits from the calibration table).
  for (int i = 0; i < NUM_JOINTS; ++i) {
    traj[i].configure(JOINT_CONFIG[i].max_vel_rad_s,
                      JOINT_CONFIG[i].max_acc_rad_s2);
  }

  // PCA9685 bring-up. All channels are forced OFF inside begin() — servos
  // stay limp until the first command. A missing board is not fatal so the
  // micro-ROS side can still be smoke-tested on the bench.
  pca9685_ok = servo.begin(PCA9685_I2C_ADDRESS, SERVO_PWM_FREQ_HZ, I2C_SDA_PIN,
                           I2C_SCL_PIN);
  if (pca9685_ok) {
    Serial.println("[arm] PCA9685 initialized, all channels off");
  } else {
    Serial.println(
        "[arm] WARNING: PCA9685 not responding on I2C (check wiring/address); "
        "continuing without servo output");
  }

  init_messages();

  // Joins WiFi and installs the UDP transport; blocks until associated.
  Serial.print("[arm] joining WiFi \"");
  Serial.print(WIFI_SSID);
  Serial.println("\" ...");
  static char wifi_ssid[] = WIFI_SSID;
  static char wifi_pass[] = WIFI_PASSWORD;
  static char agent_ip[] = AGENT_IP;
  set_microros_wifi_transports(wifi_ssid, wifi_pass, agent_ip, AGENT_PORT);
  Serial.print("[arm] WiFi up, IP ");
  Serial.print(WiFi.localIP());
  Serial.print(", agent ");
  Serial.print(agent_ip);
  Serial.print(":");
  Serial.println(AGENT_PORT);

  agent_state = WAITING_AGENT;
  uint32_t now = millis();
  last_servo_ms = now;
  last_joint_state_ms = now;
  last_status_ms = now;
  last_ping_ms = now;
  last_agent_ok_ms = now;
}

void loop() {
  uint32_t now = millis();

  // -- 50 Hz servo loop, decoupled from all ROS activity ------------------
  // Runs one fixed-dt trajectory step per elapsed SERVO_PERIOD_MS. When a
  // loop iteration was stalled (agent ping timeout, entity re-creation) the
  // backlog of missed periods is executed as catch-up steps so in-flight
  // trajectories keep wall-clock timing. A stall longer than
  // MAX_CATCHUP_STEPS periods drops the excess backlog — motion then merely
  // completes later than profiled, never faster.
  {
    uint32_t elapsed = (uint32_t)(now - last_servo_ms);
    if (elapsed >= SERVO_PERIOD_MS) {
      uint32_t steps = elapsed / SERVO_PERIOD_MS;
      if (steps > MAX_CATCHUP_STEPS) {
        steps = MAX_CATCHUP_STEPS;
        last_servo_ms = now;  // drop the un-caught-up remainder
      } else {
        last_servo_ms += steps * SERVO_PERIOD_MS;
      }
      servo_update(steps);
    }
  }

  // -- Agent connection state machine --------------------------------------
  switch (agent_state) {
    case WAITING_AGENT:
      if ((uint32_t)(now - last_ping_ms) >= PING_PERIOD_MS) {
        last_ping_ms = now;
        if (rmw_uros_ping_agent(PING_TIMEOUT_MS, 1) == RMW_RET_OK) {
          Serial.println("[arm] agent available, creating entities");
          agent_state = AGENT_AVAILABLE;
        }
      }
      break;

    case AGENT_AVAILABLE:
      if (create_entities()) {
        Serial.println("[arm] connected to agent");
        agent_state = AGENT_CONNECTED;
        now = millis();
        last_agent_ok_ms = now;
        last_ping_ms = now;
        last_joint_state_ms = now;
        last_status_ms = now;
      } else {
        Serial.println("[arm] entity creation failed, retrying");
        destroy_entities();
        agent_state = WAITING_AGENT;
      }
      break;

    case AGENT_CONNECTED:
      // Ping-based watchdog: a single missed probe is tolerated; the link
      // is declared lost only after AGENT_TIMEOUT_MS without a response.
      if ((uint32_t)(now - last_ping_ms) >= PING_PERIOD_MS) {
        last_ping_ms = now;
        if (rmw_uros_ping_agent(PING_TIMEOUT_MS, 1) == RMW_RET_OK) {
          last_agent_ok_ms = now;
        }
      }
      if ((uint32_t)(now - last_agent_ok_ms) > AGENT_TIMEOUT_MS) {
        Serial.println(
            "[arm] agent link lost >2s: holding position, reconnecting");
        agent_state = AGENT_DISCONNECTED;
        break;
      }

      // Service incoming commands (bounded, non-blocking-ish).
      (void)rclc_executor_spin_some(&executor, RCL_MS_TO_NS(2));

      if ((uint32_t)(now - last_joint_state_ms) >= JOINT_STATE_PERIOD_MS) {
        last_joint_state_ms = now;
        publish_joint_states();
      }
      if ((uint32_t)(now - last_status_ms) >= STATUS_PERIOD_MS) {
        last_status_ms = now;
        publish_status();
      }
      break;

    case AGENT_DISCONNECTED:
      // Servos HOLD: joint_armed[] stays set and the servo loop keeps
      // writing the last trajectory position; channels are never disabled.
      destroy_entities();
      agent_state = WAITING_AGENT;
      break;
  }
}
