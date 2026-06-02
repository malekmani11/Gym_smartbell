class Course {
  final int id;
  final String name;
  final String? description;
  final String? coachName;
  final int? coachId;
  final String? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final int maxParticipants;
  final int? currentParticipants;
  final String? location;
  final bool active;

  Course({
    required this.id,
    required this.name,
    this.description,
    this.coachName,
    this.coachId,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.maxParticipants = 20,
    this.currentParticipants,
    this.location,
    this.active = true,
  });

  int get spotsLeft => maxParticipants - (currentParticipants ?? 0);
  bool get isFull   => spotsLeft <= 0;

  String get timeRange {
    if (startTime == null || endTime == null) return '';
    return '$startTime – $endTime';
  }

  String get dayLabel {
    const map = {
      'MONDAY': 'Lundi', 'TUESDAY': 'Mardi', 'WEDNESDAY': 'Mercredi',
      'THURSDAY': 'Jeudi', 'FRIDAY': 'Vendredi', 'SATURDAY': 'Samedi', 'SUNDAY': 'Dimanche',
    };
    return map[dayOfWeek?.toUpperCase()] ?? (dayOfWeek ?? '');
  }

  factory Course.fromJson(Map<String, dynamic> j) => Course(
    id:                  (j['id'] ?? 0).toInt(),
    name:                j['name'] ?? j['courseName'] ?? 'Cours',
    description:         j['description'],
    coachName:           j['coachName'] ?? j['coach']?['firstName'],
    coachId:             j['coachId'] != null ? (j['coachId'] as num).toInt() : null,
    dayOfWeek:           j['dayOfWeek'],
    startTime:           j['startTime'] is String ? (j['startTime'] as String).substring(0, 5) : null,
    endTime:             j['endTime']   is String ? (j['endTime']   as String).substring(0, 5) : null,
    maxParticipants:     (j['maxParticipants'] ?? 20).toInt(),
    currentParticipants: j['currentParticipants'] != null ? (j['currentParticipants'] as num).toInt() : null,
    location:            j['location'] ?? j['room'],
    active:              j['active'] ?? true,
  );
}
