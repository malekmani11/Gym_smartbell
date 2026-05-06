class SubscriptionPlanModel {
  final int id;
  final String name;
  final String? description;
  final int durationMonths;
  final double price;
  final bool active;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    this.description,
    required this.durationMonths,
    required this.price,
    required this.active,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> j) =>
      SubscriptionPlanModel(
        id: (j['id'] ?? 0).toInt(),
        name: j['name'] ?? '',
        description: j['description'],
        durationMonths: (j['durationMonths'] ?? 0).toInt(),
        price: (j['price'] is num) ? (j['price'] as num).toDouble() : double.tryParse(j['price'].toString()) ?? 0.0,
        active: j['active'] ?? true,
      );

  String get durationLabel {
    if (durationMonths == 1) return '1 mois';
    if (durationMonths == 12) return '1 an';
    return '$durationMonths mois';
  }
}
