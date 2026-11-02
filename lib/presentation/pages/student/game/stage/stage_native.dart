import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../../domain/game/game_models.dart';
import '../../../../../domain/game/simulation_engine.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../ar/native/ar_local_server.dart';
import 'stage_html.dart';

/// Panggung 3D smart home. Menerima keadaan dari luar (perangkat terpasang,
/// kabel, dan rekaman simulasi) lalu menggambarnya. Logika game tetap di Dart.
class SmartHomeStage extends StatefulWidget {
  const SmartHomeStage({
    super.key,
    required this.mission,
    required this.installed,
    required this.wires,
    this.frame,
    this.highlightKind,
    this.onSlotTap,
    this.onFailed,
  });

  final MissionDefinition mission;

  /// ID perangkat → ID dudukan.
  final Map<String, String> installed;

  /// ID perangkat → ID pin.
  final Map<String, String> wires;

  /// Keadaan simulasi yang sedang ditampilkan.
  final TickSnapshot? frame;

  /// Dudukan jenis ini berkedip hijau (calon tempat pemasangan).
  final SlotKind? highlightKind;
  final ValueChanged<String>? onSlotTap;

  /// Dipanggil sekali jika panggung gagal, supaya layar bisa beralih ke 2D.
  final VoidCallback? onFailed;

  @override
  State<SmartHomeStage> createState() => _SmartHomeStageState();
}

class _SmartHomeStageState extends State<SmartHomeStage> {
  final List<String> _logs = <String>[];

  WebViewController? _controller;
  ArSession? _session;
  Timer? _timeout;
  bool _ready = false;
  bool _failedNotified = false;
  String? _error;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _timeout?.cancel();
    final session = _session;
    if (session != null) ArLocalServer.instance.closeSession(session.token);
    super.dispose();
  }

  void _log(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    _logs.add('$time $message');
    if (_logs.length > 80) _logs.removeAt(0);
    debugPrint('[Stage] $message');
  }

  Future<void> _start() async {
    final run = ++_run;
    _timeout?.cancel();
    setState(() {
      _ready = false;
      _error = null;
    });

    try {
      final missing = await ArLocalServer.instance.missingLibs(const [
        '/lib/aframe.min.js',
      ]);
      if (!mounted || run != _run) return;
      if (missing.isNotEmpty) {
        _fail(
          'Pustaka A-Frame belum terpasang di aplikasi (assets/ar/aframe.min.js). '
          'Periksa berkas dan pubspec.yaml, lalu jalankan ulang flutter run.',
        );
        return;
      }

      final old = _session;
      if (old != null) ArLocalServer.instance.closeSession(old.token);

      final session = await ArLocalServer.instance.openSession(
        html: buildStageHtml(),
      );
      if (!mounted || run != _run) {
        ArLocalServer.instance.closeSession(session.token);
        return;
      }
      _session = session;
      _log('server lokal: ${session.url}');

      final controller = _controller ??= _createController();
      await controller.loadRequest(Uri.parse(session.url));
      if (!mounted || run != _run) return;

      _timeout = Timer(const Duration(seconds: 30), () {
        if (!_ready) _fail('Panggung 3D tidak siap dalam 30 detik.');
      });
    } catch (e) {
      if (mounted && run == _run) _fail('Gagal menyiapkan panggung 3D: $e');
    }
  }

  WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..addJavaScriptChannel('StageBridge', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            _log(
              'webview error ${error.errorCode} ${error.description} (utama=${error.isForMainFrame})',
            );
            if (error.isForMainFrame ?? false) {
              _fail('Halaman panggung gagal dimuat: ${error.description}.');
            }
          },
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController && kDebugMode) {
      AndroidWebViewController.enableDebugging(true);
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

    switch (decoded['type']) {
      case 'webgl':
        if (decoded['ok'] == false) {
          _fail(
            'WebGL tidak tersedia di WebView perangkat ini. Perbarui "Android System '
            'WebView" dan Chrome lewat Play Store.',
          );
        }
      case 'libError':
        _fail('A-Frame tidak aktif di halaman panggung.');
      case 'sceneError':
        _fail('Adegan 3D gagal dibuat: ${decoded['message'] ?? '-'}');
      case 'ready':
        _timeout?.cancel();
        setState(() => _ready = true);
        _pushAll();
      case 'slotTapped':
        final id = decoded['id'];
        if (id is String) widget.onSlotTap?.call(id);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    _timeout?.cancel();
    _log('GAGAL: $message');
    setState(() => _error = message);
    if (!_failedNotified) {
      _failedNotified = true;
      widget.onFailed?.call();
    }
  }

  void _js(String code) {
    unawaited(
      _controller?.runJavaScript(code).catchError((Object e) {
        _log('js error: $e');
      }),
    );
  }

  Map<String, dynamic> _config() {
    final m = widget.mission;
    return {
      'slots': [
        for (final s in m.slots)
          {'id': s.id, 'kind': s.kind.name, 'label': s.label},
      ],
      'devices': [
        for (final d in m.devices) {'id': d.id, 'kind': d.kind.name},
      ],
      'pins': [
        for (final p in m.pins) {'id': p.id, 'kind': p.kind.name},
      ],
    };
  }

  void _pushFrame(TickSnapshot f) {
    final data = {
      'actuators': f.actuators,
      'observed': {for (final e in f.observed.entries) e.key.name: e.value},
    };
    _js('Stage.setFrame(${jsonEncode(data)})');
  }

  void _pushAll() {
    _js('Stage.init(${jsonEncode(_config())})');
    _js('Stage.setInstalled(${jsonEncode(widget.installed)})');
    _js('Stage.setWires(${jsonEncode(widget.wires)})');
    _js('Stage.setHighlight(${jsonEncode(widget.highlightKind?.name)})');
    final frame = widget.frame;
    if (frame != null) _pushFrame(frame);
  }

  @override
  void didUpdateWidget(SmartHomeStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;

    if (!identical(oldWidget.mission, widget.mission)) {
      _pushAll();
      return;
    }
    if (!mapEquals(oldWidget.installed, widget.installed)) {
      _js('Stage.setInstalled(${jsonEncode(widget.installed)})');
    }
    if (!mapEquals(oldWidget.wires, widget.wires)) {
      _js('Stage.setWires(${jsonEncode(widget.wires)})');
    }
    if (oldWidget.highlightKind != widget.highlightKind) {
      _js('Stage.setHighlight(${jsonEncode(widget.highlightKind?.name)})');
    }
    final frame = widget.frame;
    if (frame != null && !identical(frame, oldWidget.frame)) _pushFrame(frame);
  }

  Future<void> _copyLogs() async {
    final text = StringBuffer()
      ..writeln('Misi: ${widget.mission.id}')
      ..writeln('Siap: $_ready')
      ..writeln('Error: ${_error ?? '-'}')
      ..writeln('--- log ---');
    for (final line in _logs) {
      text.writeln(line);
    }
    await Clipboard.setData(ClipboardData(text: text.toString()));
    if (mounted) showAppSnackBar(context, 'Diagnosis disalin. Tempel ke chat.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Stack(
      children: [
        Positioned.fill(
          child: controller == null
              ? const ColoredBox(color: Color(0xFF0F172A))
              : WebViewWidget(controller: controller),
        ),
        if (!_ready && _error == null)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xFF0F172A),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Menyiapkan panggung 3D...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_error != null)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xF2000000),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          _failedNotified = false;
                          unawaited(_start());
                        },
                        child: const Text('Coba lagi'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _copyLogs,
                        icon: const Icon(Icons.copy),
                        label: const Text('Salin diagnosis'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            tooltip: 'Salin diagnosis',
            icon: const Icon(Icons.bug_report_outlined, color: Colors.white70),
            onPressed: _copyLogs,
          ),
        ),
      ],
    );
  }
}
