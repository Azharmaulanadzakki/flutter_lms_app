import 'dart:convert';

import '../../domain/entities/ar_item.dart';

/// Halaman penampil 3D (model-viewer). Model dimuat dari "model.glb"
/// di server lokal yang sama, jadi tidak ada masalah CORS.
String buildModelViewerHtml() => _modelViewerTemplate;

/// Halaman AR marker (A-Frame + MindAR). Marker dari "marker.mind",
/// model dari "model.glb", keduanya di server lokal yang sama.
String buildMarkerArHtml(ArItem item) {
  final config = jsonEncode({
    'scale': item.scale,
    'offsetY': item.offsetY,
    'rotation': [item.rotationX, item.rotationY, item.rotationZ],
    'animate': item.animate,
  });
  return _markerTemplate.split('__CONFIG__').join(config);
}

const _modelViewerTemplate = r'''
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #0F172A; }
model-viewer { width: 100%; height: 100%; background-color: #0F172A; --poster-color: transparent; }
</style>
<script>
window.__mvFailed = false;
function post(type, extra) {
  try {
    if (window.ArBridge) {
      window.ArBridge.postMessage(JSON.stringify(Object.assign({ type: type }, extra || {})));
    }
  } catch (e) {}
}
window.addEventListener("error", function (e) {
  post("jsError", { message: String(e && e.message ? e.message : e) });
});
</script>
<script type="module" src="/lib/model-viewer.min.js" onerror="window.__mvFailed = true"></script>
</head>
<body>
<model-viewer id="mv" src="model.glb" camera-controls auto-rotate touch-action="pan-y"
  shadow-intensity="1" exposure="1.1" environment-image="neutral" interaction-prompt="none"></model-viewer>
<script>
(function () {
  var gl = null;
  try {
    var c = document.createElement("canvas");
    gl = c.getContext("webgl2") || c.getContext("webgl");
  } catch (e) {}
  post("webgl", { ok: !!gl });

  var mv = document.getElementById("mv");
  mv.addEventListener("progress", function (e) {
    post("progress", { value: e.detail ? e.detail.totalProgress : 0 });
  });
  mv.addEventListener("load", function () { post("modelLoaded"); });
  mv.addEventListener("error", function (e) {
    var d = e.detail || {};
    post("modelError", {
      reason: String(d.type || ""),
      message: String((d.sourceError && d.sourceError.message) || "")
    });
  });

  customElements.whenDefined("model-viewer").then(function () { post("libReady"); });
  setTimeout(function () {
    if (window.__mvFailed || !customElements.get("model-viewer")) {
      post("libError", { detail: window.__mvFailed ? "berkas model-viewer tidak terbaca" : "model-viewer tidak aktif" });
    }
  }, 12000);

  post("htmlStarted");
})();
</script>
</body>
</html>
''';

const _markerTemplate = r'''
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }
</style>
<script src="/lib/aframe.min.js" onerror="window.__libFail = 'aframe'"></script>
<script src="/lib/mindar-image-aframe.prod.js" onerror="window.__libFail = 'mindar'"></script>
</head>
<body>
<script>
var CFG = __CONFIG__;
var modelLoadedFlag = false;

function post(type, extra) {
  try {
    if (window.ArBridge) {
      window.ArBridge.postMessage(JSON.stringify(Object.assign({ type: type }, extra || {})));
    }
  } catch (e) {}
}

window.addEventListener("error", function (e) {
  post("jsError", { message: String(e && e.message ? e.message : e) });
});

function startAr() {
  var T = AFRAME.THREE;

  AFRAME.registerComponent("play-anim", {
    init: function () {
      var self = this;
      this.mixer = null;
      this.el.addEventListener("model-loaded", function () {
        var mesh = self.el.getObject3D("mesh");
        if (!mesh || !mesh.animations || !mesh.animations.length) { return; }
        self.mixer = new T.AnimationMixer(mesh);
        mesh.animations.forEach(function (clip) { self.mixer.clipAction(clip).play(); });
      });
    },
    tick: function (time, delta) {
      if (this.mixer) { this.mixer.update(delta / 1000); }
    }
  });

  // Menyesuaikan model agar sisi terpanjangnya sama dengan lebar marker
  // (1 satuan), berdiri di tengah marker.
  function fitModel(mesh, holder) {
    try {
      var probe = mesh.clone(true);
      probe.updateMatrixWorld(true);
      var box = new T.Box3().setFromObject(probe);
      if (box.isEmpty()) {
        post("modelInfo", { empty: true });
        return;
      }
      var size = box.getSize(new T.Vector3());
      var center = box.getCenter(new T.Vector3());
      var maxDim = Math.max(size.x, size.y, size.z);
      post("modelInfo", { x: size.x, y: size.y, z: size.z });
      if (!isFinite(maxDim) || maxDim <= 0) { return; }

      var s = 1 / maxDim;
      holder.setAttribute("scale", s + " " + s + " " + s);
      holder.setAttribute("position",
        (-center.x * s) + " " + (-box.min.y * s) + " " + (-center.z * s));
    } catch (err) {
      post("jsError", { message: "fitModel: " + String(err) });
    }
  }

  var scene = document.createElement("a-scene");
  scene.setAttribute("mindar-image", {
    imageTargetSrc: "marker.mind",
    uiLoading: "no",
    uiScanning: "no",
    uiError: "no",
    maxTrack: 1
  });
  scene.setAttribute("color-space", "sRGB");
  scene.setAttribute("xr-mode-ui", "enabled: false");
  scene.setAttribute("device-orientation-permission-ui", "enabled: false");
  scene.setAttribute("gltf-model", "dracoDecoderPath: https://www.gstatic.com/draco/v1/decoders/");

  var camera = document.createElement("a-camera");
  camera.setAttribute("position", "0 0 0");
  camera.setAttribute("look-controls", "enabled: false");
  camera.setAttribute("wasd-controls", "enabled: false");
  scene.appendChild(camera);

  var ambient = document.createElement("a-entity");
  ambient.setAttribute("light", "type: ambient; intensity: 1.2; color: #ffffff");
  scene.appendChild(ambient);

  var hemi = document.createElement("a-entity");
  hemi.setAttribute("light", "type: hemisphere; intensity: 1.2; color: #ffffff; groundColor: #aaaaaa");
  scene.appendChild(hemi);

  var sun = document.createElement("a-entity");
  sun.setAttribute("light", "type: directional; intensity: 2; color: #ffffff");
  sun.setAttribute("position", "0.5 1 1");
  scene.appendChild(sun);

  var fill = document.createElement("a-entity");
  fill.setAttribute("light", "type: directional; intensity: 1.2; color: #ffffff");
  fill.setAttribute("position", "-0.5 0.5 -1");
  scene.appendChild(fill);

  var target = document.createElement("a-entity");
  target.setAttribute("mindar-image-target", "targetIndex: 0");

  var userHolder = document.createElement("a-entity");
  userHolder.setAttribute("position", "0 " + CFG.offsetY + " 0");
  userHolder.setAttribute("rotation", CFG.rotation.join(" "));
  userHolder.setAttribute("scale", CFG.scale + " " + CFG.scale + " " + CFG.scale);

  var fitHolder = document.createElement("a-entity");

  var model = document.createElement("a-entity");
  model.setAttribute("gltf-model", "url(model.glb)");
  if (CFG.animate) { model.setAttribute("play-anim", ""); }

  model.addEventListener("model-loaded", function () {
    modelLoadedFlag = true;
    var mesh = model.getObject3D("mesh");
    if (mesh) { fitModel(mesh, fitHolder); }
    post("modelLoaded");
  });
  model.addEventListener("model-error", function () { post("modelError", { reason: "model-error" }); });
  target.addEventListener("targetFound", function () { post("found", { modelLoaded: modelLoadedFlag }); });
  target.addEventListener("targetLost", function () { post("lost"); });
  scene.addEventListener("arReady", function () {
    post("ready");
    setTimeout(function () {
      var v = document.querySelector("video");
      var cs = window.getComputedStyle(document.body);
      post("videoInfo", {
        found: !!v,
        w: v ? v.videoWidth : 0,
        h: v ? v.videoHeight : 0,
        readyState: v ? v.readyState : -1,
        paused: v ? v.paused : null,
        z: v ? window.getComputedStyle(v).zIndex : null,
        bodyBg: cs.backgroundColor
      });
    }, 1200);
  });  scene.addEventListener("arError", function () { post("arError"); });

  fitHolder.appendChild(model);
  userHolder.appendChild(fitHolder);
  target.appendChild(userHolder);
  scene.appendChild(target);
  document.body.appendChild(scene);
}

window.addEventListener("load", function () {
  var hasA = !!window.AFRAME;
  var hasM = !!(hasA && AFRAME.components && AFRAME.components["mindar-image"]);
  post("htmlStarted", { aframe: hasA, mindar: hasM });

  if (!hasA || !hasM) {
    post("libError", {
      detail: (!hasA ? "A-Frame tidak aktif" : "MindAR tidak aktif") +
        (window.__libFail ? " (berkas " + window.__libFail + " tidak terbaca)" : "")
    });
    return;
  }
  startAr();
});
</script>
</body>
</html>
''';
