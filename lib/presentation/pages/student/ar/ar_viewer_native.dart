import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/ar/ar_html.dart';
import '../../../../core/ar/test_cube_glb.dart';
import '../../../../domain/entities/ar_item.dart';
import '../../../../injection_container.dart';
import '../../../blocs/ar/ar_cubits.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/ar_widgets.dart';
import '../../../widgets/state_views.dart';
import 'ar_view_mode.dart';
import 'native/ar_asset_cache.dart';
import 'native/ar_local_server.dart';

const String _sceneViewerPackage = 'com.google.android.googlequicksearchbox';

bool get isArPlatformSupported => Platform.isAndroid;

/// AR tanpa marker: membuka Google Scene Viewer (butuh ARCore).
/// Mengembalikan pesan error, atau null jika berhasil dibuka.
Future<String?> launchSceneViewer({
  required String modelUrl,
  required String title,
}) async {
  if (!Platform.isAndroid) return 'AR tanpa marker hanya tersedia di Android.';

  try {
    final uri = Uri.https('arvr.google.com', '/scene-viewer/1.0', {
      'file': modelUrl,
      'mode': 'ar_preferred',
      'title': title,
    });
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: uri.toString(),
      package: _sceneViewerPackage,
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
    return null;
  } on PlatformException {
    return 'Scene Viewer tidak bisa dibuka. Pastikan aplikasi Google dan '
        '"Layanan Google Play untuk AR" terpasang, dan HP mendukung ARCore.';
  } catch (_) {
    return 'Gagal membuka AR tanpa marker.';
  }
}

class ArViewerScreen extends StatelessWidget {
  const ArViewerScreen({super.key, this.itemId, required this.mode});

  final String? itemId;
  final ArViewMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == ArViewMode.selfTest) {
      return const _ArWebScreen(item: null, mode: ArViewMode.selfTest);
    }

    final id = itemId ?? '';
    return BlocProvider(
      create: (_) => sl<ArItemCubit>()..load(id),
      child: BlocBuilder<ArItemCubit, ArItemState>(
        builder: (context, state) {
          final item = state.item;
          if (item != null) return _ArWebScreen(item: item, mode: mode);

          return Scaffold(
            appBar: AppBar(title: Text(mode.title)),
            body: state.status == ArLoadStatus.failure
                ? ErrorView(
                    message: state.error ?? 'Gagal memuat model AR.',
                    onRetry: () => context.read<ArItemCubit>().load(id),
                  )
                : const LoadingView(),
          );
        },
      ),
    );
  }
}

enum _StepState { pending, running, done, failed }

class _Step {
  _Step(this.label);

  final String label;
  _StepState state = _StepState.pending;
  String? detail;
}

enum _Phase { loading, needsCamera, ready, error }

class _Fail implements Exception {
  _Fail(this.message);

  final String message;
}

class _ArWebScreen extends StatefulWidget {
  const _ArWebScreen({required this.item, required this.mode});

  final ArItem? item;
  final ArViewMode mode;

  @override
  State<_ArWebScreen> createState() => _ArWebScreenState();
}

class _ArWebScreenState extends State<_ArWebScreen>
    with WidgetsBindingObserver {
  final Map<String, _Step> _steps = <String, _Step>{};
  final List<String> _logs = <String>[];

  WebViewController? _controller;
  ArSession? _session;
  Timer? _timeout;

  _Phase _phase = _Phase.loading;
  String? _error;
  double? _downloadProgress;
  bool _permanentlyDenied = false;
  bool _libReady = false;
  bool _modelLoaded = false;
  bool _cameraReady = false;
  bool _found = false;
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _steps['lib'] = _Step('Pustaka AR (di dalam aplikasi)');
    _steps['model'] = _Step(
      widget.mode == ArViewMode.selfTest
          ? 'Model uji (kubus bawaan)'
          : 'Unduh model 3D',
    );
    if (widget.mode == ArViewMode.marker) {
      _steps['marker'] = _Step('Unduh marker (.mind)');
      _steps['camera'] = _Step('Izin kamera');
    }
    _steps['render'] = _Step(
      widget.mode == ArViewMode.marker
          ? 'Kamera dan pelacakan marker'
          : 'Render 3D',
    );

    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeout?.cancel();
    final session = _session;
    if (session != null) ArLocalServer.instance.closeSession(session.token);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kembali dari Pengaturan: lanjut otomatis jika izin kamera sudah diberikan.
    if (state == AppLifecycleState.resumed && _phase == _Phase.needsCamera) {
      Permission.camera.status.then((status) {
        if (mounted && status.isGranted) unawaited(_start());
      });
    }
  }

  void _log(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    _logs.add('$time $message');
    if (_logs.length > 80) _logs.removeAt(0);
    debugPrint('[AR] $message');
  }

  void _setStep(String key, _StepState state, [String? detail]) {
    final step = _steps[key];
    if (step == null || !mounted) return;
    setState(() {
      step.state = state;
      if (detail != null) step.detail = detail;
    });
  }

  Future<void> _start() async {
    final run = ++_runId;
    bool stale() => !mounted || run != _runId;

    _timeout?.cancel();
    final old = _session;
    if (old != null) {
      ArLocalServer.instance.closeSession(old.token);
      _session = null;
    }

    setState(() {
      _phase = _Phase.loading;
      _error = null;
      _downloadProgress = null;
      _libReady = false;
      _modelLoaded = false;
      _cameraReady = false;
      _found = false;
      for (final s in _steps.values) {
        s.state = _StepState.pending;
        s.detail = null;
      }
    });

    final item = widget.item;
    final mode = widget.mode;
    _log('mulai: mode=${mode.name}');

    try {
      // 1. Pustaka
      _setStep('lib', _StepState.running);
      final missing = await ArLocalServer.instance.missingLibs(
        mode.requiredLibs,
      );
      if (stale()) return;
      if (missing.isNotEmpty) {
        throw _Fail(
          'Pustaka AR belum terpasang di aplikasi (${missing.join(', ')}). '
          'Salin berkas ke assets/ar/, daftarkan di pubspec.yaml, lalu jalankan '
          'ulang flutter run (bukan hot restart).',
        );
      }
      _setStep('lib', _StepState.done, 'terpasang');

      // 2. Model
      File? modelFile;
      Uint8List? modelBytes;
      if (mode == ArViewMode.selfTest) {
        modelBytes = buildTestCubeGlb();
        _setStep(
          'model',
          _StepState.done,
          '${modelBytes.length} byte, dibuat di aplikasi',
        );
      } else {
        modelFile = await _download('model', item!.modelUrl, stale);
        if (stale()) return;
        if (!await ArAssetCache.looksLikeGlb(modelFile)) {
          await ArAssetCache.delete(modelFile);
          throw _Fail(
            'Berkas model bukan GLB yang valid. Biasanya link menunjuk ke halaman web, '
            'bukan ke file. Unggah ulang lewat form admin.',
          );
        }
        _setStep(
          'model',
          _StepState.done,
          ArAssetCache.formatBytes(await modelFile.length()),
        );
      }

      // 3. Marker dan kamera
      File? markerFile;
      if (mode == ArViewMode.marker) {
        final markerUrl = item!.markerUrl.trim();
        if (markerUrl.isEmpty) {
          throw _Fail(
            'Model ini belum punya marker (.mind). Unggah di form admin.',
          );
        }
        markerFile = await _download('marker', markerUrl, stale);
        if (stale()) return;
        _setStep(
          'marker',
          _StepState.done,
          ArAssetCache.formatBytes(await markerFile.length()),
        );

        _setStep('camera', _StepState.running);
        final granted = await _ensureCamera();
        if (stale()) return;
        if (!granted) {
          _setStep('camera', _StepState.failed, 'izin ditolak');
          setState(() => _phase = _Phase.needsCamera);
          return;
        }
        _setStep('camera', _StepState.done, 'diizinkan');
      }

      // 4. Halaman AR
      _setStep('render', _StepState.running, 'menyiapkan halaman');
      final html = mode == ArViewMode.marker
          ? buildMarkerArHtml(item!)
          : buildModelViewerHtml();
      final session = await ArLocalServer.instance.openSession(
        html: html,
        modelFile: modelFile,
        modelBytes: modelBytes,
        markerFile: markerFile,
      );
      if (stale()) {
        ArLocalServer.instance.closeSession(session.token);
        return;
      }
      _session = session;
      _log('server lokal: ${session.url}');

      final controller = _controller ??= _createController();
      await controller.loadRequest(Uri.parse(session.url));
      if (stale()) return;

      _setStep('render', _StepState.running, 'menunggu halaman');
      _timeout = Timer(const Duration(seconds: 60), _onTimeout);
    } on _Fail catch (f) {
      if (!stale()) _fail(f.message);
    } on ArDownloadException catch (e) {
      if (!stale()) _fail(e.message);
    } catch (e) {
      if (!stale()) _fail('Terjadi kesalahan tak terduga: $e');
    }
  }

  Future<File> _download(String key, String url, bool Function() stale) async {
    _setStep(key, _StepState.running, 'menghubungi server...');
    var lastPercent = -1;

    return ArAssetCache.fetch(
      url,
      onProgress: (fraction) {
        if (stale() || fraction == null) return;
        final percent = (fraction * 100).floor();
        if (percent == lastPercent) return;
        lastPercent = percent;
        _downloadProgress = fraction;
        _setStep(key, _StepState.running, 'mengunduh $percent%');
      },
    );
  }

  Future<bool> _ensureCamera() async {
    final status = await Permission.camera.request();
    _permanentlyDenied = status.isPermanentlyDenied;
    return status.isGranted;
  }

  WebViewController _createController() {
    final controller =
        WebViewController(
            onPermissionRequest: (request) {
              if (request.types.contains(
                WebViewPermissionResourceType.camera,
              )) {
                request.grant();
              } else {
                request.deny();
              }
            },
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..addJavaScriptChannel('ArBridge', onMessageReceived: _onMessage)
          ..setNavigationDelegate(
            NavigationDelegate(
              onWebResourceError: (error) {
                _log(
                  'webview error ${error.errorCode} ${error.description} (utama=${error.isForMainFrame})',
                );
                if (error.isForMainFrame ?? false) {
                  _fail('Halaman AR gagal dimuat: ${error.description}.');
                }
              },
            ),
          );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      if (kDebugMode) AndroidWebViewController.enableDebugging(true);
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    return controller;
  }

  void _onMessage(JavaScriptMessage message) {
    if (!mounted) return;

    final Object? decoded;
    try {
      decoded = jsonDecode(message.message);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;

    _log('web: ${message.message}');
    final type = decoded['type']?.toString() ?? '';

    switch (type) {
      case 'webgl':
        if (decoded['ok'] == false) {
          _fail(
            'WebGL tidak tersedia di WebView perangkat ini. Perbarui "Android System '
            'WebView" dan Chrome lewat Play Store.',
          );
        }
      case 'libReady':
        setState(() => _libReady = true);
      case 'libError':
        _fail(
          'Pustaka gagal dijalankan di halaman: ${decoded['detail'] ?? '-'}.',
        );
      case 'modelError':
        _fail(
          'Model gagal dirender (${decoded['reason'] ?? 'tidak diketahui'} ${decoded['message'] ?? ''}). '
          'Kemungkinan GLB rusak, terlalu besar, atau memakai kompresi (Draco/KTX2) '
          'yang butuh internet ke gstatic.com.',
        );
      case 'modelLoaded':
        _modelLoaded = true;
        if (widget.mode == ArViewMode.marker) {
          _setStep(
            'render',
            _StepState.running,
            _cameraReady ? 'model siap' : 'model siap, menunggu kamera',
          );
        }
        _maybeReady();
      case 'ready':
        _cameraReady = true;
        _setStep(
          'render',
          _StepState.running,
          _modelLoaded ? 'kamera siap' : 'kamera siap, menunggu model',
        );
        _maybeReady();
      case 'found':
        setState(() => _found = true);
      case 'lost':
        setState(() => _found = false);
      case 'arError':
        _fail(
          'Kamera atau pelacakan gagal dimulai. Pastikan izin kamera aktif dan kamera '
          'tidak dipakai aplikasi lain. File marker (.mind) juga bisa rusak.',
        );
    }
  }

  void _maybeReady() {
    final ok = widget.mode == ArViewMode.marker
        ? (_modelLoaded && _cameraReady)
        : _modelLoaded;
    if (!ok || _phase != _Phase.loading) return;

    _timeout?.cancel();
    setState(() {
      _phase = _Phase.ready;
      final render = _steps['render']!;
      render.state = _StepState.done;
      render.detail = 'siap';
    });
  }

  void _onTimeout() {
    if (!mounted || _phase != _Phase.loading) return;

    final waiting = <String>[
      if (widget.mode != ArViewMode.marker && !_libReady) 'pustaka renderer',
      if (!_modelLoaded) 'model 3D',
      if (widget.mode == ArViewMode.marker && !_cameraReady) 'kamera',
    ];
    _fail(
      'Waktu habis (60 detik) saat menunggu: ${waiting.isEmpty ? 'halaman' : waiting.join(', ')}. '
      'Tekan "Salin diagnosis" dan kirim ke pengembang.',
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    _timeout?.cancel();
    _log('GAGAL: $message');
    setState(() {
      _phase = _Phase.error;
      _error = message;
      for (final s in _steps.values) {
        if (s.state == _StepState.running) s.state = _StepState.failed;
      }
    });
  }

  Future<void> _copyDiagnostics() async {
    final item = widget.item;
    final buffer = StringBuffer()
      ..writeln('Mode: ${widget.mode.name}')
      ..writeln('Item: ${item?.title ?? '-'}')
      ..writeln('Model: ${item?.modelUrl ?? '(kubus bawaan)'}')
      ..writeln('Marker: ${item?.markerUrl ?? '-'}')
      ..writeln('Fase: ${_phase.name}')
      ..writeln('Error: ${_error ?? '-'}');
    for (final step in _steps.values) {
      buffer.writeln(
        '[${step.state.name}] ${step.label}: ${step.detail ?? ''}',
      );
    }
    buffer.writeln('--- log ---');
    for (final line in _logs) {
      buffer.writeln(line);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) showAppSnackBar(context, 'Diagnosis disalin. Tempel ke chat.');
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          item?.title ?? widget.mode.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (item != null &&
              widget.mode == ArViewMode.marker &&
              item.markerImageUrl.isNotEmpty)
            IconButton(
              tooltip: 'Lihat marker',
              icon: const Icon(Icons.image_outlined),
              onPressed: () => showMarkerDialog(context, item),
            ),
          if (item != null && item.credit.isNotEmpty)
            IconButton(
              tooltip: 'Kredit model',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showCreditDialog(context, item),
            ),
          IconButton(
            tooltip: 'Salin diagnosis',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _copyDiagnostics,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_phase == _Phase.needsCamera) {
      return _CameraNeeded(
        permanentlyDenied: _permanentlyDenied,
        onAction: () {
          if (_permanentlyDenied) {
            openAppSettings();
          } else {
            unawaited(_start());
          }
        },
      );
    }

    final controller = _controller;
    return Stack(
      children: [
        if (controller != null)
          Positioned.fill(child: WebViewWidget(controller: controller)),
        if (_phase == _Phase.loading)
          Positioned.fill(
            child: _LoadingOverlay(
              steps: _steps.values.toList(),
              progress: _downloadProgress,
            ),
          ),
        if (_phase == _Phase.error)
          Positioned.fill(
            child: _ErrorOverlay(
              message: _error ?? 'Terjadi kesalahan pada AR.',
              onRetry: () => unawaited(_start()),
              onCopy: _copyDiagnostics,
            ),
          ),
        if (_phase == _Phase.ready)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: _HintPill(mode: widget.mode, found: _found),
            ),
          ),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.steps, required this.progress});

  final List<_Step> steps;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xF2000000),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menyiapkan AR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              for (final step in steps) _StepRow(step: step),
              if (progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
              ],
              const SizedBox(height: 16),
              const Text(
                'Pertama kali bisa memakan waktu beberapa detik. Berikutnya lebih cepat '
                'karena file disimpan di HP.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final Widget icon;
    switch (step.state) {
      case _StepState.pending:
        icon = const Icon(
          Icons.radio_button_unchecked,
          size: 20,
          color: Colors.white38,
        );
      case _StepState.running:
        icon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      case _StepState.done:
        icon = Icon(Icons.check_circle, size: 20, color: Colors.green.shade400);
      case _StepState.failed:
        icon = Icon(Icons.error, size: 20, color: Colors.red.shade400);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label, style: const TextStyle(color: Colors.white)),
                if (step.detail != null && step.detail!.isNotEmpty)
                  Text(
                    step.detail!,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onRetry,
    required this.onCopy,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xF2000000),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                  foregroundColor: Colors.white,
                ),
                onPressed: onCopy,
                icon: const Icon(Icons.copy),
                label: const Text('Salin diagnosis'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraNeeded extends StatelessWidget {
  const _CameraNeeded({
    required this.permanentlyDenied,
    required this.onAction,
  });

  final bool permanentlyDenied;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              permanentlyDenied
                  ? 'Izin kamera ditolak. Aktifkan izin kamera di Pengaturan agar AR marker bisa dipakai.'
                  : 'AR marker membutuhkan izin kamera untuk mengenali marker.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
              onPressed: onAction,
              child: Text(
                permanentlyDenied ? 'Buka Pengaturan' : 'Izinkan Kamera',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.mode, required this.found});

  final ArViewMode mode;
  final bool found;

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;
    var color = Colors.black87;

    switch (mode) {
      case ArViewMode.marker:
        text = found ? 'Marker terdeteksi' : 'Arahkan kamera ke gambar marker';
        icon = found ? Icons.check_circle : Icons.center_focus_strong;
        if (found) color = Colors.green.shade700;
      case ArViewMode.selfTest:
        text = 'Kubus biru tampil = HP-mu bisa merender 3D';
        icon = Icons.check_circle;
        color = Colors.green.shade700;
      case ArViewMode.model3d:
        text = 'Geser untuk memutar, cubit untuk zoom';
        icon = Icons.threed_rotation;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
