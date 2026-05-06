class StatisticsModel {
  final int totalMembers;
  final int activeMembers;
  final int totalCoaches;
  final int totalCheckInsToday;
  final double revenueThisMonth;
  final double revenueThisYear;
  final int activeSubscriptions;
  final int totalCourses;

  StatisticsModel({
    this.totalMembers = 0, this.activeMembers = 0,
    this.totalCoaches = 0, this.totalCheckInsToday = 0,
    this.revenueThisMonth = 0, this.revenueThisYear = 0,
    this.activeSubscriptions = 0, this.totalCourses = 0,
  });

  factory StatisticsModel.fromJson(Map<String, dynamic> j) => StatisticsModel(
    totalMembers:       (j['totalMembers']       ?? 0).toInt(),
    activeMembers:      (j['activeMembers']      ?? 0).toInt(),
    totalCoaches:       (j['totalCoaches']       ?? 0).toInt(),
    totalCheckInsToday: (j['totalCheckInsToday'] ?? 0).toInt(),
    revenueThisMonth:   (j['revenueThisMonth']   ?? 0).toDouble(),
    revenueThisYear:    (j['revenueThisYear']    ?? 0).toDouble(),
    activeSubscriptions:(j['activeSubscriptions']?? 0).toInt(),
    totalCourses:       (j['totalCourses']       ?? 0).toInt(),
  );
}
