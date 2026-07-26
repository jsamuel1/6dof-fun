// Touchscreen jog + calibrate panel.
//
// Topics (see docs/superpowers/specs/2026-07-19-touchscreen-ui-design.md):
//   pub /arm/joint_commands  sensor_msgs/JointState  (one named joint, radians)
//   pub /arm/cal             std_msgs/String         (firmware diag alphabet)
//   pub /arm/audio/enable    std_msgs/Bool           (mic on/off)
//   sub /joint_states        sensor_msgs/JointState
//   sub /arm/status          std_msgs/String (JSON @ 1 Hz)
//   sub /arm/audio           std_msgs/String (JSON @ ~5 Hz, buzz detector)

'use strict';

const NUM_JOINTS = 6;
const JOINT_NAMES = ['joint1', 'joint2', 'joint3', 'joint4', 'joint5', 'joint6'];
const JOINT_TITLES = ['base', 'shoulder', 'elbow', 'wrist p', 'wrist r', 'grip'];
const LIMIT_DEG = 90;              // UI clamp; firmware clamps authoritatively
const DEG = Math.PI / 180;
const STATUS_STALE_MS = 3000;

const host = location.hostname || 'localhost';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
const positions = new Array(NUM_JOINTS).fill(0);   // radians, from /joint_states
let havePositions = false;                         // false until first /joint_states
let selected = 0;                                  // selected row (cal channel)
let calMode = false;
let rosConnected = false;
let lastStatusMs = 0;
let calUs = null, calCh = null;
let micOn = null;                  // null until first /arm/audio message
let buzzHideAt = 0;                // latch: overlay visible until this time

// ---------------------------------------------------------------------------
// rosbridge connection with backoff
// ---------------------------------------------------------------------------
let ros = null;
let cmdTopic = null, calTopic = null, micTopic = null;
let retryDelay = 500;

function connect() {
  ros = new ROSLIB.Ros({ url: `ws://${host}:9090` });

  ros.on('connection', () => {
    rosConnected = true;
    retryDelay = 500;
    cmdTopic = new ROSLIB.Topic({
      ros, name: '/arm/joint_commands', messageType: 'sensor_msgs/JointState',
    });
    calTopic = new ROSLIB.Topic({
      ros, name: '/arm/cal', messageType: 'std_msgs/String',
    });
    micTopic = new ROSLIB.Topic({
      ros, name: '/arm/audio/enable', messageType: 'std_msgs/Bool',
    });

    const audio = new ROSLIB.Topic({
      ros, name: '/arm/audio', messageType: 'std_msgs/String',
    });
    audio.subscribe((msg) => {
      try {
        const a = JSON.parse(msg.data);
        micOn = !!a.enabled;
        if (a.buzz) buzzHideAt = Date.now() + 800;   // latch past detector flicker
        renderAudio(a);
      } catch (_) { /* malformed audio msg — ignore */ }
    });

    const js = new ROSLIB.Topic({
      ros, name: '/joint_states', messageType: 'sensor_msgs/JointState',
    });
    js.subscribe((msg) => {
      for (let k = 0; k < msg.name.length; ++k) {
        const i = JOINT_NAMES.indexOf(msg.name[k]);
        if (i >= 0 && k < msg.position.length) positions[i] = msg.position[k];
      }
      havePositions = true;
      renderReadouts();
    });

    const st = new ROSLIB.Topic({
      ros, name: '/arm/status', messageType: 'std_msgs/String',
    });
    st.subscribe((msg) => {
      lastStatusMs = Date.now();
      try {
        const s = JSON.parse(msg.data);
        calCh = s.cal_ch; calUs = s.cal_us;
        document.getElementById('st-rssi').textContent = `rssi ${s.rssi} dBm`;
        document.getElementById('st-uptime').textContent = `up ${fmtUptime(s.uptime_s)}`;
        document.getElementById('st-estop').classList.toggle('hidden', !s.estop);
        document.getElementById('dot-agent').classList.toggle('ok', !!s.agent_connected);
        renderCalStrip();
      } catch (_) { /* malformed status — ignore */ }
    });

    renderConnection();
  });

  const onDown = () => {
    if (ros) { ros.close(); ros = null; }
    rosConnected = false;
    cmdTopic = calTopic = micTopic = null;
    renderConnection();
    setTimeout(connect, retryDelay);
    retryDelay = Math.min(retryDelay * 2, 5000);
  };
  ros.on('error', onDown);
  ros.on('close', onDown);
}

// ---------------------------------------------------------------------------
// Publishing
// ---------------------------------------------------------------------------
function jog(i, stepDeg) {
  if (!rosConnected || !cmdTopic) return;
  let deg = positions[i] / DEG + stepDeg;
  deg = Math.max(-LIMIT_DEG, Math.min(LIMIT_DEG, deg));
  cmdTopic.publish(new ROSLIB.Message({
    header: { stamp: { sec: 0, nanosec: 0 }, frame_id: '' },
    name: [JOINT_NAMES[i]],
    position: [deg * DEG],
    velocity: [],
    effort: [],
  }));
}

function sendCal(ch) {
  if (!rosConnected || !calTopic) return;
  calTopic.publish(new ROSLIB.Message({ data: ch }));
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------
function fmtUptime(s) {
  if (s == null) return '—';
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
  return h ? `${h}h${String(m).padStart(2, '0')}m` : `${m}m${String(s % 60).padStart(2, '0')}s`;
}

function renderConnection() {
  document.getElementById('banner').classList.toggle('hidden', rosConnected);
  document.getElementById('dot-ros').classList.toggle('ok', rosConnected);
  document.querySelectorAll('button').forEach((b) => {
    if (b.id !== 'cam-retry') b.disabled = !rosConnected;
  });
}

function renderReadouts() {
  for (let i = 0; i < NUM_JOINTS; ++i) {
    const el = document.getElementById(`val-${i}`);
    if (el && !(calMode && i === selected)) {
      el.textContent = havePositions ? `${(positions[i] / DEG).toFixed(1)}°` : '—';
    }
  }
}

function renderAudio(a) {
  const btn = document.getElementById('mic-toggle');
  btn.classList.toggle('on', micOn === true);
  document.getElementById('st-audio').textContent =
    micOn ? `mic ${a.band_db} dB` : 'mic off';
  document.getElementById('buzz-overlay')
    .classList.toggle('hidden', Date.now() >= buzzHideAt);
}

function renderCalStrip() {
  const chTxt = (calCh == null || calCh < 0) ? '—' : calCh;
  document.getElementById('st-cal').textContent =
    `cal ch ${chTxt} / ${calUs == null ? '—' : calUs} µs`;
  if (calMode) {
    const el = document.getElementById(`val-${selected}`);
    if (el && calUs != null) el.textContent = `${calUs} µs`;
  }
}

// A row is jog mode (deg steps) or, when calMode && selected, µs nudge mode.
function rowButtons(i) {
  if (calMode && i === selected) {
    return [
      { t: '−50', act: () => sendCal('<') },
      { t: '−10', act: () => sendCal('-') },
      { t: '+10', act: () => sendCal('+') },
      { t: '+50', act: () => sendCal('>') },
    ];
  }
  return [
    { t: '◀◀', act: () => jog(i, -10) },
    { t: '◀', act: () => jog(i, -2) },
    { t: '▶', act: () => jog(i, +2) },
    { t: '▶▶', act: () => jog(i, +10) },
  ];
}

function renderRows() {
  const root = document.getElementById('joints');
  root.innerHTML = '';
  for (let i = 0; i < NUM_JOINTS; ++i) {
    const row = document.createElement('div');
    row.className = 'row' + (i === selected ? ' selected' : '');
    const btns = rowButtons(i);

    const mk = (b) => {
      const el = document.createElement('button');
      el.className = 'btn';
      el.textContent = b.t;
      el.disabled = !rosConnected;
      el.addEventListener('click', (ev) => { ev.stopPropagation(); b.act(); });
      return el;
    };

    row.appendChild(mk(btns[0]));
    row.appendChild(mk(btns[1]));

    const label = document.createElement('div');
    label.className = 'label';
    label.innerHTML = `<span class="name">${JOINT_TITLES[i]} · ${JOINT_NAMES[i]}</span>` +
                      `<span class="val" id="val-${i}">—</span>`;
    row.appendChild(label);

    row.appendChild(mk(btns[2]));
    row.appendChild(mk(btns[3]));

    row.addEventListener('click', () => selectRow(i));
    root.appendChild(row);
  }
  renderReadouts();
  renderCalStrip();
}

function selectRow(i) {
  selected = i;
  if (calMode) sendCal(String(i));   // cal channel select ('0'-'5')
  renderRows();
}

// ---------------------------------------------------------------------------
// Wiring: STOP, cal toggle, camera, status staleness
// ---------------------------------------------------------------------------
document.getElementById('stop').addEventListener('click', () => sendCal('x'));

document.getElementById('mic-toggle').addEventListener('click', () => {
  if (!rosConnected || !micTopic) return;
  const next = micOn === null ? false : !micOn;   // detector defaults on
  micTopic.publish(new ROSLIB.Message({ data: next }));
});

document.getElementById('cal-toggle').addEventListener('click', () => {
  calMode = !calMode;
  document.getElementById('cal-toggle').classList.toggle('on', calMode);
  if (calMode) sendCal(String(selected));
  renderRows();
});

const camImg = document.getElementById('cam-img');
const camUrl = `http://${host}:8080/stream?topic=/image_raw&type=mjpeg`;
let camRot = 0;
function camStart() {
  document.getElementById('cam-fallback').classList.add('hidden');
  camImg.classList.remove('hidden');
  camImg.src = `${camUrl}&t=${Date.now()}`;   // bust any stale connection
}
camImg.addEventListener('error', () => {
  camImg.removeAttribute('src');
  camImg.classList.add('hidden');
  document.getElementById('cam-fallback').classList.remove('hidden');
});
camImg.addEventListener('click', () => {
  camRot = (camRot + 90) % 360;
  camImg.className = camRot ? `rot${camRot}` : '';
});
document.getElementById('cam-retry').addEventListener('click', camStart);

setInterval(() => {
  if (Date.now() - lastStatusMs > STATUS_STALE_MS) {
    document.getElementById('dot-agent').classList.remove('ok');
  }
  // clear the buzz latch even if no fresh /arm/audio message arrives
  if (buzzHideAt && Date.now() >= buzzHideAt) {
    document.getElementById('buzz-overlay').classList.add('hidden');
    buzzHideAt = 0;
  }
}, 250);

// ---------------------------------------------------------------------------
renderRows();
renderConnection();
connect();
// Start the MJPEG stream only after the page's load event: the stream never
// "finishes", and starting it earlier holds the document in loading state
// forever (breaks load-based tooling and Chromium's spinner).
window.addEventListener('load', camStart);
