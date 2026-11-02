/// Halaman HTML panggung 3D. Seluruh benda dirakit dari bentuk dasar,
/// jadi tidak ada model atau gambar yang diunduh. Hanya A-Frame yang
/// dimuat, dari server lokal aplikasi.
String buildStageHtml() => _template;

const _template = r'''
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #0F172A; }
</style>
<script src="/lib/aframe.min.js"></script>
</head>
<body>
<script>
var T = null;
var Stage = null;

function post(type, extra) {
  try {
    if (window.StageBridge) {
      window.StageBridge.postMessage(JSON.stringify(Object.assign({ type: type }, extra || {})));
    }
  } catch (e) {}
}

window.addEventListener('error', function (e) {
  post('jsError', { message: String(e && e.message ? e.message : e) });
});

function createStage(scene, camEl) {
  var root = scene.object3D;
  var canvas = scene.canvas;
  var shaded = [];
  var state = { actuators: {}, observed: { temperature: 26, light: 500, motion: 0 } };
  var installed = {};
  var wires = {};
  var cfg = { slots: [], devices: [], pins: [] };
  var slotObjs = {};
  var devices = {};
  var pinPos = {};
  var hitMeshes = [];
  var highlight = null;
  var lastShade = -1;
  var frames = 0;
  var failed = false;
  var orbit = { az: 0.3, pol: 1.0, dist: 9.5 };
  var target = new T.Vector3(0, 1.3, -1.4);
  var bgDay = new T.Color(0xbfdbfe);
  var bgNight = new T.Color(0x0b1220);
  root.background = bgDay.clone();

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

  // ---------- bahan dan bentuk dasar ----------
  function mat(color) {
    var m = new T.MeshBasicMaterial({ color: color });
    shaded.push({ m: m, base: new T.Color(color) });
    return m;
  }
  function glow(color) { return new T.MeshBasicMaterial({ color: color }); }
  function outline(mesh, geo, angle) {
    mesh.add(new T.LineSegments(
      new T.EdgesGeometry(geo, angle || 30),
      new T.LineBasicMaterial({ color: 0x0f172a })
    ));
    return mesh;
  }
  function box(w, h, d, color) {
    var g = new T.BoxGeometry(w, h, d);
    return outline(new T.Mesh(g, mat(color)), g);
  }
  function cyl(rt, rb, h, color, seg) {
    var g = new T.CylinderGeometry(rt, rb, h, seg || 20);
    return outline(new T.Mesh(g, mat(color)), g, 40);
  }
  function ball(r, color) { return new T.Mesh(new T.SphereGeometry(r, 16, 12), mat(color)); }

  function label(text) {
    var c = document.createElement('canvas');
    c.width = 256;
    c.height = 64;
    var g = c.getContext('2d');
    g.fillStyle = 'rgba(15,23,42,0.88)';
    g.fillRect(0, 0, 256, 64);
    g.fillStyle = '#ffffff';
    g.font = 'bold 22px sans-serif';
    g.textAlign = 'center';
    g.textBaseline = 'middle';
    g.fillText(String(text), 128, 32);
    var sprite = new T.Sprite(new T.SpriteMaterial({
      map: new T.CanvasTexture(c),
      depthTest: false,
      transparent: true
    }));
    sprite.scale.set(1.1, 0.28, 1);
    sprite.renderOrder = 10;
    return sprite;
  }

  function cable(a, b, color) {
    var dir = new T.Vector3().subVectors(b, a);
    var len = dir.length();
    var m = new T.Mesh(
      new T.CylinderGeometry(0.025, 0.025, Math.max(len, 0.01), 6),
      new T.MeshBasicMaterial({ color: color })
    );
    m.position.copy(a).addScaledVector(dir, 0.5);
    m.quaternion.setFromUnitVectors(new T.Vector3(0, 1, 0), dir.clone().normalize());
    return m;
  }

  // ---------- ruangan ----------
  var room = new T.Group();
  root.add(room);
  function put(obj, x, y, z) {
    obj.position.set(x, y, z);
    room.add(obj);
    return obj;
  }

  put(box(9, 0.1, 8, 0x94a3b8), 0, -0.05, 0);
  put(box(9, 3.6, 0.15, 0xe2e8f0), 0, 1.8, -4.0);
  put(box(0.15, 3.6, 8, 0xcbd5e1), -4.5, 1.8, 0);
  put(box(1.3, 2.3, 0.1, 0x92400e), 2.6, 1.15, -3.88);
  put(box(4, 0.08, 0.08, 0x64748b), 0.8, 3.4, -1.2);

  // meja dan papan ESP32
  put(box(1.5, 0.08, 1.0, 0xb45309), -2.6, 0.8, -3.2);
  put(box(0.08, 0.8, 0.08, 0x78350f), -3.3, 0.4, -3.6);
  put(box(0.08, 0.8, 0.08, 0x78350f), -1.9, 0.4, -3.6);
  put(box(0.08, 0.8, 0.08, 0x78350f), -3.3, 0.4, -2.8);
  put(box(0.08, 0.8, 0.08, 0x78350f), -1.9, 0.4, -2.8);
  put(box(1.0, 0.05, 0.6, 0x166534), -2.6, 0.865, -3.2);
  put(box(0.3, 0.04, 0.3, 0x0f172a), -2.6, 0.9, -3.25);

  // termometer dinding
  put(box(0.2, 1.1, 0.04, 0xf1f5f9), 1.0, 1.75, -3.9);
  var thermoBar = new T.Mesh(new T.BoxGeometry(0.08, 1, 0.03), glow(0x3b82f6));
  thermoBar.position.set(1.0, 1.3, -3.86);
  room.add(thermoBar);

  // orang (tampil saat sensor gerak mendeteksi)
  var person = new T.Group();
  var body = cyl(0.16, 0.2, 0.9, 0x2563eb, 16);
  body.position.y = 0.45;
  person.add(body);
  var head = ball(0.16, 0xfcd34d);
  head.position.y = 1.1;
  person.add(head);
  person.position.set(0.3, 0, -1.2);
  person.visible = false;
  room.add(person);

  // ---------- lapisan yang bergantung pada misi ----------
  var dyn = new T.Group();
  root.add(dyn);
  var cableGroup = new T.Group();
  dyn.add(cableGroup);
  var pinGroup = null;

  function slotPose(kind, index) {
    if (kind === 'sensor') return { pos: new T.Vector3(-1.4 + index * 1.0, 2.0, -3.85), rotY: 0 };
    if (kind === 'ceiling') return { pos: new T.Vector3(0.2 + index * 1.2, 3.1, -1.2), rotY: 0 };
    if (kind === 'wall') return { pos: new T.Vector3(-4.4, 2.0, -1.0 + index * 1.6), rotY: Math.PI / 2 };
    return { pos: new T.Vector3(1.85, 1.1, -3.82), rotY: 0 };
  }

  // ---------- perangkat ----------
  function motionSensor(u) {
    var g = new T.Group();
    g.add(box(0.28, 0.28, 0.12, 0xf8fafc));
    var dome = new T.Mesh(
      new T.SphereGeometry(0.1, 16, 12, 0, Math.PI * 2, 0, Math.PI / 2),
      mat(0xe2e8f0)
    );
    dome.rotation.x = Math.PI / 2;
    dome.position.z = 0.06;
    g.add(dome);
    var ledMat = glow(0x7f1d1d);
    var led = new T.Mesh(new T.SphereGeometry(0.03, 8, 8), ledMat);
    led.position.set(0.1, 0.1, 0.07);
    g.add(led);
    u.tick = function () {
      var on = u.live && state.observed.motion > 0.5;
      ledMat.color.set(on ? 0xef4444 : 0x7f1d1d);
    };
    return g;
  }

  function tempSensor(u) {
    var g = new T.Group();
    g.add(box(0.22, 0.34, 0.1, 0x1d4ed8));
    var grille = box(0.14, 0.1, 0.02, 0x93c5fd);
    grille.position.z = 0.06;
    g.add(grille);
    var ledMat = glow(0x14532d);
    var led = new T.Mesh(new T.SphereGeometry(0.03, 8, 8), ledMat);
    led.position.set(0.07, -0.12, 0.06);
    g.add(led);
    u.tick = function () {
      var hot = u.live && state.observed.temperature > 30;
      ledMat.color.set(hot ? 0xf97316 : (u.live ? 0x22c55e : 0x14532d));
    };
    return g;
  }

  function lightSensor(u) {
    var g = new T.Group();
    g.add(box(0.22, 0.22, 0.1, 0x854d0e));
    var discMat = glow(0x78350f);
    var disc = new T.Mesh(new T.CylinderGeometry(0.09, 0.09, 0.03, 20), discMat);
    disc.rotation.x = Math.PI / 2;
    disc.position.z = 0.07;
    g.add(disc);
    u.tick = function () {
      var k = clamp(state.observed.light / 600, 0, 1);
      discMat.color.set(0x78350f).lerp(new T.Color(0xfde047), k);
    };
    return g;
  }

  function lamp(u) {
    var g = new T.Group();
    var cord = cyl(0.012, 0.012, 0.3, 0x475569, 6);
    cord.position.y = 0.15;
    g.add(cord);
    var shade = cyl(0.08, 0.3, 0.26, 0xf8fafc, 24);
    shade.position.y = -0.1;
    g.add(shade);
    var bulbMat = glow(0x78716c);
    var bulb = new T.Mesh(new T.SphereGeometry(0.1, 16, 12), bulbMat);
    bulb.position.y = -0.28;
    g.add(bulb);
    var haloMat = new T.MeshBasicMaterial({ color: 0xfef08a, transparent: true, opacity: 0, depthWrite: false });
    var halo = new T.Mesh(new T.SphereGeometry(0.55, 16, 12), haloMat);
    halo.position.y = -0.3;
    g.add(halo);
    var poolMat = new T.MeshBasicMaterial({ color: 0xfef08a, transparent: true, opacity: 0, depthWrite: false });
    var pool = new T.Mesh(new T.CircleGeometry(1.5, 28), poolMat);
    pool.rotation.x = -Math.PI / 2;
    g.add(pool);
    u.level = 0;
    u.tick = function (dt) {
      var on = state.actuators[u.id] === true;
      u.level += ((on ? 1 : 0) - u.level) * Math.min(1, dt * 8);
      bulbMat.color.set(0x78716c).lerp(new T.Color(0xfef08a), u.level);
      haloMat.opacity = 0.35 * u.level;
      poolMat.opacity = 0.5 * u.level;
      pool.position.y = 0.02 - g.position.y;
    };
    return g;
  }

  function fan(u) {
    var g = new T.Group();
    g.add(box(0.24, 0.24, 0.12, 0x475569));
    var blades = new T.Group();
    blades.position.z = 0.12;
    g.add(blades);
    for (var i = 0; i < 3; i++) {
      var blade = box(0.12, 0.5, 0.02, 0xe2e8f0);
      blade.position.y = 0.25;
      var pivot = new T.Group();
      pivot.rotation.z = i * (Math.PI * 2 / 3);
      pivot.add(blade);
      blades.add(pivot);
    }
    var hub = cyl(0.06, 0.06, 0.06, 0x1e293b, 16);
    hub.rotation.x = Math.PI / 2;
    hub.position.z = 0.12;
    g.add(hub);
    var ring = new T.Mesh(new T.TorusGeometry(0.34, 0.015, 8, 28), mat(0x64748b));
    ring.position.z = 0.12;
    g.add(ring);
    u.omega = 0;
    u.tick = function (dt) {
      var on = state.actuators[u.id] === true;
      u.omega += ((on ? 14 : 0) - u.omega) * Math.min(1, dt * 3);
      blades.rotation.z += u.omega * dt;
    };
    return g;
  }

  function buzzer(u) {
    var g = new T.Group();
    var housing = cyl(0.17, 0.17, 0.09, 0x1f2937, 24);
    housing.rotation.x = Math.PI / 2;
    g.add(housing);
    var capMat = glow(0x7f1d1d);
    var cap = new T.Mesh(new T.CylinderGeometry(0.07, 0.07, 0.02, 16), capMat);
    cap.rotation.x = Math.PI / 2;
    cap.position.z = 0.055;
    g.add(cap);
    var ringMat = new T.MeshBasicMaterial({ color: 0xef4444, transparent: true, opacity: 0, depthWrite: false });
    var ring = new T.Mesh(new T.TorusGeometry(0.22, 0.015, 8, 28), ringMat);
    ring.position.z = 0.06;
    g.add(ring);
    u.tick = function (dt, t) {
      var on = state.actuators[u.id] === true;
      if (on) {
        var ph = (t * 2.5) % 1;
        ring.scale.setScalar(1 + ph * 1.6);
        ringMat.opacity = 0.8 * (1 - ph);
        capMat.color.set(Math.floor(t * 6) % 2 === 0 ? 0xef4444 : 0x7f1d1d);
      } else {
        ringMat.opacity = 0;
        capMat.color.set(0x7f1d1d);
      }
    };
    return g;
  }

  function doorLock(u) {
    var g = new T.Group();
    g.add(box(0.2, 0.3, 0.08, 0x334155));
    var bolt = cyl(0.035, 0.035, 0.22, 0xcbd5e1, 12);
    bolt.rotation.z = Math.PI / 2;
    g.add(bolt);
    var ledMat = glow(0x22c55e);
    var led = new T.Mesh(new T.SphereGeometry(0.035, 10, 8), ledMat);
    led.position.set(0, 0.1, 0.05);
    g.add(led);
    u.k = 0;
    u.tick = function (dt) {
      var locked = state.actuators[u.id] === true;
      u.k += ((locked ? 1 : 0) - u.k) * Math.min(1, dt * 6);
      bolt.position.x = 0.2 * u.k;
      ledMat.color.set(locked ? 0xef4444 : 0x22c55e);
    };
    return g;
  }

  function makeDevice(kind, id) {
    var u = { id: id, kind: kind, live: false, tick: function () {} };
    var g;
    if (kind === 'motionSensor') g = motionSensor(u);
    else if (kind === 'tempSensor') g = tempSensor(u);
    else if (kind === 'lightSensor') g = lightSensor(u);
    else if (kind === 'lamp') g = lamp(u);
    else if (kind === 'fan') g = fan(u);
    else if (kind === 'buzzer') g = buzzer(u);
    else if (kind === 'doorLock') g = doorLock(u);
    else g = new T.Group();
    g.userData = u;
    g.visible = false;
    return g;
  }

  // ---------- keadaan ----------
  function clearDyn() {
    for (var i = dyn.children.length - 1; i >= 0; i--) {
      var child = dyn.children[i];
      if (child !== cableGroup) dyn.remove(child);
    }
    while (cableGroup.children.length) cableGroup.remove(cableGroup.children[0]);
    slotObjs = {};
    devices = {};
    pinPos = {};
    hitMeshes.length = 0;
    pinGroup = null;
  }

  function buildPins(pins) {
    pinGroup = new T.Group();
    dyn.add(pinGroup);
    var n = pins.length;
    for (var i = 0; i < n; i++) {
      var x = -3.0 + (n === 1 ? 0.4 : (0.8 * i) / (n - 1));
      var kind = pins[i].kind;
      var color = kind === 'analog' ? 0x4ade80 : (kind === 'pwm' ? 0xfb923c : 0x38bdf8);
      var pin = new T.Mesh(new T.CylinderGeometry(0.04, 0.04, 0.08, 10), new T.MeshBasicMaterial({ color: color }));
      pin.position.set(x, 0.93, -2.9);
      pinGroup.add(pin);
      pinPos[pins[i].id] = new T.Vector3(x, 0.95, -2.9);
      var tag = label(pins[i].id);
      tag.scale.set(0.42, 0.11, 1);
      tag.position.set(x, 1.12, -2.85);
      pinGroup.add(tag);
    }
  }

  function applyWires() {
    while (cableGroup.children.length) cableGroup.remove(cableGroup.children[0]);
    var kinds = {};
    for (var i = 0; i < cfg.pins.length; i++) kinds[cfg.pins[i].id] = cfg.pins[i].kind;

    for (var id in devices) {
      var g = devices[id];
      var pinId = wires[id];
      var slot = installed[id] ? slotObjs[installed[id]] : null;
      g.userData.live = !!(slot && pinId && pinPos[pinId]);
      if (!g.userData.live) continue;
      var kind = kinds[pinId];
      var color = kind === 'analog' ? 0x16a34a : (kind === 'pwm' ? 0xea580c : 0x0284c7);
      cableGroup.add(cable(slot.pose.pos, pinPos[pinId], color));
    }
  }

  function applyInstalled() {
    var occupied = {};
    for (var id in devices) {
      var g = devices[id];
      var sid = installed[id];
      var slot = sid ? slotObjs[sid] : null;
      if (slot) {
        g.visible = true;
        g.position.copy(slot.pose.pos);
        g.rotation.y = slot.pose.rotY;
        occupied[sid] = true;
      } else {
        g.visible = false;
      }
    }
    for (var key in slotObjs) {
      var so = slotObjs[key];
      var occ = !!occupied[key];
      so.occupied = occ;
      so.ring.visible = !occ;
      so.label.visible = !occ;
    }
    applyWires();
  }

  function init(c) {
    cfg = { slots: c.slots || [], devices: c.devices || [], pins: c.pins || [] };
    clearDyn();

    var counters = {};
    for (var i = 0; i < cfg.slots.length; i++) {
      var s = cfg.slots[i];
      var idx = counters[s.kind] || 0;
      counters[s.kind] = idx + 1;
      var pose = slotPose(s.kind, idx);

      var g = new T.Group();
      g.position.copy(pose.pos);
      g.rotation.y = pose.rotY;

      var ring = new T.Mesh(
        new T.TorusGeometry(0.22, 0.03, 8, 28),
        new T.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.6 })
      );
      if (s.kind === 'ceiling') ring.rotation.x = Math.PI / 2;
      g.add(ring);

      var hit = new T.Mesh(
        new T.SphereGeometry(0.42, 10, 8),
        new T.MeshBasicMaterial({ transparent: true, opacity: 0, depthWrite: false })
      );
      hit.userData.slotId = s.id;
      g.add(hit);

      var tag = label(s.label);
      tag.position.set(0, 0.42, 0);
      g.add(tag);

      dyn.add(g);
      slotObjs[s.id] = { group: g, ring: ring, label: tag, kind: s.kind, pose: pose, occupied: false };
      hitMeshes.push(hit);
    }

    for (var j = 0; j < cfg.devices.length; j++) {
      var d = cfg.devices[j];
      var dg = makeDevice(d.kind, d.id);
      dyn.add(dg);
      devices[d.id] = dg;
    }

    buildPins(cfg.pins);
    installed = {};
    wires = {};
    applyInstalled();
  }

  function applyShade(s) {
    lastShade = s;
    for (var i = 0; i < shaded.length; i++) {
      shaded[i].m.color.copy(shaded[i].base).multiplyScalar(s);
    }
    root.background.copy(bgNight).lerp(bgDay, clamp((s - 0.35) / 0.65, 0, 1));
  }

  function updateCamera() {
    var sp = Math.sin(orbit.pol);
    var pos = new T.Vector3(
      target.x + orbit.dist * sp * Math.sin(orbit.az),
      target.y + orbit.dist * Math.cos(orbit.pol),
      target.z + orbit.dist * sp * Math.cos(orbit.az)
    );
    camEl.object3D.position.copy(pos);
    var m = new T.Matrix4().lookAt(pos, target, new T.Vector3(0, 1, 0));
    camEl.object3D.quaternion.setFromRotationMatrix(m);
  }

  function tick(t, dt) {
    if (failed) return;
    try {
      frames++;
      updateCamera();

      var ob = state.observed;
      var shade = clamp(0.35 + 0.65 * (ob.light / 600), 0.35, 1);
      if (Math.abs(shade - lastShade) > 0.01) applyShade(shade);

      person.visible = ob.motion > 0.5;

      var th = clamp((ob.temperature - 20) / 20, 0, 1);
      var h = Math.max(0.03, th * 0.9);
      thermoBar.scale.y = h;
      thermoBar.position.y = 1.25 + h / 2;
      thermoBar.material.color.set(0x3b82f6).lerp(new T.Color(0xef4444), th);

      for (var id in devices) devices[id].userData.tick(dt, t);

      for (var key in slotObjs) {
        var so = slotObjs[key];
        if (highlight && so.kind === highlight && !so.occupied) {
          so.ring.material.color.set(0x22c55e);
          so.ring.material.opacity = 0.95;
          so.ring.scale.setScalar(1 + 0.15 * Math.sin(t * 5));
        } else {
          so.ring.material.color.set(0xffffff);
          so.ring.material.opacity = 0.6;
          so.ring.scale.setScalar(1);
        }
      }

      if (frames === 30) {
        var info = scene.renderer.info.render;
        post('rendering', { calls: info.calls, triangles: info.triangles });
      }
    } catch (err) {
      failed = true;
      post('sceneError', { message: String(err && err.message ? err.message : err) });
    }
  }

  // ---------- sentuhan: putar, cubit, ketuk ----------
  var pointers = new Map();
  var tap = null;
  var pinchStart = 0;
  var distStart = 0;
  var raycaster = new T.Raycaster();

  function pinchDistance() {
    var pts = Array.from(pointers.values());
    if (pts.length < 2) return 0;
    return Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
  }

  function doTap(x, y) {
    var rect = canvas.getBoundingClientRect();
    var nx = ((x - rect.left) / rect.width) * 2 - 1;
    var ny = -((y - rect.top) / rect.height) * 2 + 1;
    scene.camera.updateMatrixWorld(true);
    raycaster.setFromCamera({ x: nx, y: ny }, scene.camera);
    var hits = raycaster.intersectObjects(hitMeshes, false);
    if (hits.length > 0) post('slotTapped', { id: hits[0].object.userData.slotId });
  }

  canvas.style.touchAction = 'none';

  canvas.addEventListener('pointerdown', function (e) {
    try { canvas.setPointerCapture(e.pointerId); } catch (err) {}
    pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.size === 1) {
      tap = { x: e.clientX, y: e.clientY, t: Date.now(), moved: false };
    } else {
      tap = null;
      pinchStart = pinchDistance();
      distStart = orbit.dist;
    }
  });

  canvas.addEventListener('pointermove', function (e) {
    var p = pointers.get(e.pointerId);
    if (!p) return;
    var dx = e.clientX - p.x;
    var dy = e.clientY - p.y;
    p.x = e.clientX;
    p.y = e.clientY;

    if (pointers.size === 1) {
      orbit.az = clamp(orbit.az - dx * 0.008, -1.3, 1.3);
      orbit.pol = clamp(orbit.pol - dy * 0.006, 0.4, 1.45);
      if (tap && (Math.abs(e.clientX - tap.x) > 8 || Math.abs(e.clientY - tap.y) > 8)) tap.moved = true;
    } else if (pointers.size === 2 && pinchStart > 0) {
      var d = pinchDistance();
      if (d > 0) orbit.dist = clamp(distStart * pinchStart / d, 4, 16);
    }
  });

  function endPointer(e) {
    if (tap && !tap.moved && pointers.size === 1 && Date.now() - tap.t < 600) {
      doTap(e.clientX, e.clientY);
    }
    pointers.delete(e.pointerId);
    tap = null;
  }
  canvas.addEventListener('pointerup', endPointer);
  canvas.addEventListener('pointercancel', function (e) {
    pointers.delete(e.pointerId);
    tap = null;
  });

  return {
    init: init,
    setInstalled: function (m) { installed = m || {}; applyInstalled(); },
    setWires: function (m) { wires = m || {}; applyWires(); },
    setHighlight: function (kind) { highlight = kind || null; },
    setFrame: function (f) {
      if (!f) return;
      if (f.actuators) state.actuators = f.actuators;
      if (f.observed) {
        state.observed = {
          temperature: Number(f.observed.temperature),
          light: Number(f.observed.light),
          motion: Number(f.observed.motion)
        };
      }
    },
    tick: tick
  };
}

function boot() {
  AFRAME.registerComponent('stage-tick', {
    tick: function (time, dt) {
      if (Stage) Stage.tick(time / 1000, Math.min(dt / 1000, 0.1));
    }
  });

  var scene = document.createElement('a-scene');
  scene.setAttribute('renderer', 'antialias: true');
  scene.setAttribute('vr-mode-ui', 'enabled: false');
  scene.setAttribute('device-orientation-permission-ui', 'enabled: false');
  scene.setAttribute('stage-tick', '');

  var camEl = document.createElement('a-entity');
  camEl.setAttribute('camera', 'fov: 50');
  camEl.setAttribute('look-controls', 'enabled: false');
  camEl.setAttribute('wasd-controls', 'enabled: false');
  scene.appendChild(camEl);

  scene.addEventListener('loaded', function () {
    try {
      Stage = createStage(scene, camEl);
      post('ready');
    } catch (err) {
      post('sceneError', { message: String(err && err.message ? err.message : err) });
    }
  });
  document.body.appendChild(scene);
}

window.addEventListener('load', function () {
  if (!window.AFRAME) {
    post('libError');
    return;
  }
  T = AFRAME.THREE;

  var gl = null;
  try {
    var c = document.createElement('canvas');
    gl = c.getContext('webgl2') || c.getContext('webgl');
  } catch (e) {}
  post('webgl', { ok: !!gl });
  if (!gl) return;

  try {
    boot();
  } catch (err) {
    post('sceneError', { message: String(err && err.message ? err.message : err) });
  }
});
</script>
</body>
</html>
''';