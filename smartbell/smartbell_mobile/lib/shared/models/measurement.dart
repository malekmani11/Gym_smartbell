class Measurement {
  final int? id;
  final int memberId;
  final DateTime date;
  final double weight; // kg
  final double height; // cm
  final String? notes;

  const Measurement({
    this.id,
    required this.memberId,
    required this.date,
    required this.weight,
    required this.height,
    this.notes,
  });

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiLabel {
    final b = bmi;
    if (b < 18.5) return 'Insuffisant';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Surpoids';
    return 'Obèse';
  }

  factory Measurement.fromJson(Map<String, dynamic> j) => Measurement(
        id:       j['id'] != null ? (j['id'] as num).toInt() : null,
        memberId: (j['memberId'] ?? 0).toInt(),
        date:     j['date'] != null
            ? DateTime.parse(j['date'].toString())
            : DateTime.now(),
        weight: (j['weight'] as num).toDouble(),
        height: (j['height'] as num).toDouble(),
        notes:  j['notes']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'memberId': memberId,
        'date':     date.toIso8601String(),
        'weight':   weight,
        'height':   height,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
