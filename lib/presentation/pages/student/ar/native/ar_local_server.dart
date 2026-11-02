import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

class ArSession {
  const ArSession(this.token, this.url);

  final String token;

  /// Alamat halaman utama yang dimuat WebView.
  final String url;
}

class _Entry {
  _Entry.bytes(this.bytes, this.type) : file = null;
  _Entry.file(this.file, this.type) : bytes = null;

  final Uint8List? bytes;
  final File? file;
  final String type;
}

/// Server HTTP kecil di 127.0.0.1. Halaman AR, pustaka JavaScript, model, dan
/// marker disajikan dari satu alamat yang sama, sehingga tidak ada CDN dan
/// tidak ada masalah CORS.
class ArLocalServer {
  ArLocalServer._();

  static final ArLocalServer instance = ArLocalServer._();

  static const Map<String, String> _libAssets = {
    '/lib/aframe.min.js': 'assets/ar/aframe.min.js',
    '/lib/mindar-image-aframe.prod.js': 'assets/ar/mindar-image-aframe.prod.js',
    '/lib/model-viewer.min.js': 'assets/ar/model-viewer.min.js',
  };

  HttpServer? _server;
  Future<HttpServer>? _starting;
  final Map<String, _Entry> _entries = {};
  final Map<String, Uint8List> _libCache = {};
  final Random _random = Random.secure();

  Future<HttpServer> _ensureStarted() {
    final existing = _server;
    if (existing != null) return Future.value(existing);

    return _starting ??= HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        .then((server) {
          _server = server;
          server.listen(_handle, onError: (Object _) {});
          return server;
        })
        .catchError((Object e) {
          _starting = null;
          throw e;
        });
  }

  /// Daftar berkas aset yang belum terpasang di aplikasi.
  Future<List<String>> missingLibs(List<String> paths) async {
    final missing = <String>[];
    for (final path in paths) {
      final asset = _libAssets[path];
      if (asset == null || await _loadLib(path) == null) {
        missing.add(asset ?? path);
      }
    }
    return missing;
  }

  Future<ArSession> openSession({
    required String html,
    File? modelFile,
    Uint8List? modelBytes,
    File? markerFile,
  }) async {
    final server = await _ensureStarted();
    final token = _newToken();
    final base = '/s/$token';

    _entries['$base/index.html'] = _Entry.bytes(
      Uint8List.fromList(utf8.encode(html)),
      'text/html; charset=utf-8',
    );

    if (modelFile != null) {
      _entries['$base/model.glb'] = _Entry.file(modelFile, 'model/gltf-binary');
    } else if (modelBytes != null) {
      _entries['$base/model.glb'] = _Entry.bytes(
        modelBytes,
        'model/gltf-binary',
      );
    }
    if (markerFile != null) {
      _entries['$base/marker.mind'] = _Entry.file(
        markerFile,
        'application/octet-stream',
      );
    }

    return ArSession(token, 'http://127.0.0.1:${server.port}$base/index.html');
  }

  void closeSession(String token) {
    _entries.removeWhere((key, _) => key.startsWith('/s/$token/'));
  }

  String _newToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<Uint8List?> _loadLib(String path) async {
    final cached = _libCache[path];
    if (cached != null) return cached;

    final asset = _libAssets[path];
    if (asset == null) return null;

    try {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (bytes.isEmpty) return null;
      _libCache[path] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;

    try {
      if (request.method != 'GET') {
        response.statusCode = HttpStatus.methodNotAllowed;
        await response.close();
        return;
      }

      final path = request.uri.path;
      response.headers.set('Cache-Control', 'no-store');

      if (_libAssets.containsKey(path)) {
        final bytes = await _loadLib(path);
        if (bytes == null) {
          response.statusCode = HttpStatus.notFound;
          await response.close();
          return;
        }
        response.headers.contentType = ContentType(
          'application',
          'javascript',
          charset: 'utf-8',
        );
        response.contentLength = bytes.length;
        response.add(bytes);
        await response.close();
        return;
      }

      final entry = _entries[path];
      if (entry == null) {
        response.statusCode = HttpStatus.notFound;
        await response.close();
        return;
      }

      response.headers.set(HttpHeaders.contentTypeHeader, entry.type);
      final bytes = entry.bytes;
      if (bytes != null) {
        response.contentLength = bytes.length;
        response.add(bytes);
      } else {
        final file = entry.file!;
        response.contentLength = await file.length();
        await response.addStream(file.openRead());
      }
      await response.close();
    } catch (_) {
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } catch (_) {}
    }
  }
}
