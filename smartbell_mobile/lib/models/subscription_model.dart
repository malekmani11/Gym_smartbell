class SubscriptionModel {
  final int id;
  final int userId;
  final int planId;
  final String? planName;
  final String? startDate;
  final String? endDate;
  final String? status;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    this.planName,
    this.startDate,
    this.endDate,
    this.status,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> j) =>
      SubscriptionModel(
        id: (j['id'] ?? 0).toInt(),
        userId: (j['userId'] ?? 0).toInt(),
        planId: (j['planId'] ?? 0).toInt(),
        planName: j['planName'],
        startDate: j['startDate'],
        endDate: j['endDate'],
        status: j['status'],
      );

  bool get isActive => status?.toUpperCase() == 'ACTIVE';

  int get daysRemaining {
    if (endDate == null) return 0;
    final end = DateTime.tryParse(endDate!);
    if (end == null) return 0;
    final diff = end.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get totalDays {
    if (startDate == null || endDate == null) return 30;
    final start = DateTime.tryParse(startDate!);
    final end = DateTime.tryParse(endDate!);
    if (start == null || end == null) return 30;
    return end.difference(start).inDays;
  }
}
