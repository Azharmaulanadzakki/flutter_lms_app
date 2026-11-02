/// Operator perbandingan pada blok JIKA.
enum CompareOp { gt, lt, gte, lte, eq }

extension CompareOpX on CompareOp {
  String get symbol => switch (this) {
    CompareOp.gt => '>',
    CompareOp.lt => '<',
    CompareOp.gte => '≥',
    CompareOp.lte => '≤',
    CompareOp.eq => '=',
  };

  bool test(double value, double threshold) => switch (this) {
    CompareOp.gt => value > threshold,
    CompareOp.lt => value < threshold,
    CompareOp.gte => value >= threshold,
    CompareOp.lte => value <= threshold,
    CompareOp.eq => (value - threshold).abs() < 1e-9,
  };
}

/// Cara menggabungkan beberapa kondisi dalam satu aturan.
enum Joiner { and, or }

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

/// Satu syarat, misalnya "suhu > 30".
class Condition {
  const Condition(this.deviceId, this.op, this.threshold);

  /// ID sensor yang dibaca.
  final String deviceId;
  final CompareOp op;
  final double threshold;

  Map<String, dynamic> toJson() => {
    'device': deviceId,
    'op': op.name,
    'value': threshold,
  };

  static Condition? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final device = json['device'];
    final op = _enumByName(CompareOp.values, json['op']);
    final value = json['value'];
    if (device is! String || op == null || value is! num) return null;
    return Condition(device, op, value.toDouble());
  }
}

/// Perintah ke perangkat keluaran: nyalakan atau matikan.
/// Untuk kunci pintu, `on` berarti terkunci.
class RuleAction {
  const RuleAction(this.deviceId, this.on);

  final String deviceId;
  final bool on;

  Map<String, dynamic> toJson() => {'device': deviceId, 'on': on};

  static RuleAction? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final device = json['device'];
    final on = json['on'];
    if (device is! String || on is! bool) return null;
    return RuleAction(device, on);
  }
}

/// JIKA (kondisi) MAKA (aksi) LAINNYA (aksi).
class Rule {
  const Rule({
    required this.conditions,
    this.joiner = Joiner.and,
    required this.thenActions,
    this.elseActions = const [],
  });

  final List<Condition> conditions;
  final Joiner joiner;
  final List<RuleAction> thenActions;
  final List<RuleAction> elseActions;

  Map<String, dynamic> toJson() => {
    'conditions': [for (final c in conditions) c.toJson()],
    'joiner': joiner.name,
    'then': [for (final a in thenActions) a.toJson()],
    'else': [for (final a in elseActions) a.toJson()],
  };

  /// Null jika [json] bukan bentuk aturan. Bagian yang rusak dilewati.
  static Rule? tryFromJson(Object? json) {
    if (json is! Map) return null;

    List<T> parseList<T>(Object? raw, T? Function(Object?) parse) {
      final out = <T>[];
      if (raw is List) {
        for (final item in raw) {
          final value = parse(item);
          if (value != null) out.add(value);
        }
      }
      return out;
    }

    return Rule(
      conditions: parseList(json['conditions'], Condition.tryFromJson),
      joiner: _enumByName(Joiner.values, json['joiner']) ?? Joiner.and,
      thenActions: parseList(json['then'], RuleAction.tryFromJson),
      elseActions: parseList(json['else'], RuleAction.tryFromJson),
    );
  }
}
