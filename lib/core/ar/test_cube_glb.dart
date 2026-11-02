import 'dart:convert';
import 'dart:typed_data';

/// Membuat file GLB berisi sebuah kubus biru, seluruhnya di memori.
/// Dipakai untuk "Tes Render" tanpa internet.
Uint8List buildTestCubeGlb() {
  const h = 0.5;

  // Tiap sisi: [normal, v0, v1, v2, v3], berlawanan arah jarum jam dari luar.
  final faces = <List<List<double>>>[
    [
      [1.0, 0.0, 0.0],
      [h, -h, h],
      [h, -h, -h],
      [h, h, -h],
      [h, h, h],
    ],
    [
      [-1.0, 0.0, 0.0],
      [-h, -h, -h],
      [-h, -h, h],
      [-h, h, h],
      [-h, h, -h],
    ],
    [
      [0.0, 1.0, 0.0],
      [-h, h, h],
      [h, h, h],
      [h, h, -h],
      [-h, h, -h],
    ],
    [
      [0.0, -1.0, 0.0],
      [-h, -h, -h],
      [h, -h, -h],
      [h, -h, h],
      [-h, -h, h],
    ],
    [
      [0.0, 0.0, 1.0],
      [-h, -h, h],
      [h, -h, h],
      [h, h, h],
      [-h, h, h],
    ],
    [
      [0.0, 0.0, -1.0],
      [h, -h, -h],
      [-h, -h, -h],
      [-h, h, -h],
      [h, h, -h],
    ],
  ];

  // 24 posisi (288 B) + 24 normal (288 B) + 36 indeks uint16 (72 B) = 648 B.
  final bin = ByteData(648);
  var o = 0;

  for (final f in faces) {
    for (var i = 1; i <= 4; i++) {
      for (final c in f[i]) {
        bin.setFloat32(o, c, Endian.little);
        o += 4;
      }
    }
  }
  for (final f in faces) {
    for (var i = 0; i < 4; i++) {
      for (final c in f[0]) {
        bin.setFloat32(o, c, Endian.little);
        o += 4;
      }
    }
  }
  for (var face = 0; face < 6; face++) {
    final b = face * 4;
    for (final idx in [b, b + 1, b + 2, b, b + 2, b + 3]) {
      bin.setUint16(o, idx, Endian.little);
      o += 2;
    }
  }

  final json = jsonEncode({
    'asset': {'version': '2.0', 'generator': 'smk-tkj-lms'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0],
      },
    ],
    'nodes': [
      {'mesh': 0},
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {'POSITION': 0, 'NORMAL': 1},
            'indices': 2,
            'material': 0,
          },
        ],
      },
    ],
    'materials': [
      {
        'pbrMetallicRoughness': {
          'baseColorFactor': [0.15, 0.45, 0.95, 1.0],
          'metallicFactor': 0.1,
          'roughnessFactor': 0.6,
        },
      },
    ],
    'buffers': [
      {'byteLength': 648},
    ],
    'bufferViews': [
      {'buffer': 0, 'byteOffset': 0, 'byteLength': 288, 'target': 34962},
      {'buffer': 0, 'byteOffset': 288, 'byteLength': 288, 'target': 34962},
      {'buffer': 0, 'byteOffset': 576, 'byteLength': 72, 'target': 34963},
    ],
    'accessors': [
      {
        'bufferView': 0,
        'componentType': 5126,
        'count': 24,
        'type': 'VEC3',
        'min': [-0.5, -0.5, -0.5],
        'max': [0.5, 0.5, 0.5],
      },
      {'bufferView': 1, 'componentType': 5126, 'count': 24, 'type': 'VEC3'},
      {'bufferView': 2, 'componentType': 5123, 'count': 36, 'type': 'SCALAR'},
    ],
  });

  final jsonBytes = utf8.encode(json);
  final padding = (4 - jsonBytes.length % 4) % 4;
  final jsonChunk = Uint8List(jsonBytes.length + padding)
    ..setAll(0, jsonBytes)
    ..fillRange(jsonBytes.length, jsonBytes.length + padding, 0x20);

  final total = 12 + 8 + jsonChunk.length + 8 + bin.lengthInBytes;
  final out = Uint8List(total);
  final view = ByteData.view(out.buffer);

  view.setUint32(0, 0x46546C67, Endian.little); // "glTF"
  view.setUint32(4, 2, Endian.little);
  view.setUint32(8, total, Endian.little);

  view.setUint32(12, jsonChunk.length, Endian.little);
  view.setUint32(16, 0x4E4F534A, Endian.little); // "JSON"
  out.setRange(20, 20 + jsonChunk.length, jsonChunk);

  final p = 20 + jsonChunk.length;
  view.setUint32(p, bin.lengthInBytes, Endian.little);
  view.setUint32(p + 4, 0x004E4942, Endian.little); // "BIN\0"
  out.setRange(p + 8, p + 8 + bin.lengthInBytes, bin.buffer.asUint8List());

  return out;
}
