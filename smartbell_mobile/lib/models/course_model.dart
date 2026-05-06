class CourseModel {
  final int? id;
  final String name;
  final String? description;
  final String? coachName;
  final String? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final int maxParticipants;
  final String? location;
  final bool active;

  CourseModel({
    this.id, required this.name, this.description, this.coachName,
    this.dayOfWeek, this.startTime, this.endTime,
    this.maxParticipants = 20, this.location, this.active = true,
  });

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
    id:              j['id'],
    name:            j['name']         ?? '',
    description:     j['description'],
    coachName:       j['coachName'],
    dayOfWeek:       j['dayOfWeek'],
    startTime:       j['startTime'],
    endTime:         j['endTime'],
    maxParticipants: j['maxParticipants'] ?? 20,
    location:        j['location'],
    active:          j['active'] ?? true,
  );

  String get timeRange =>
    '${(startTime ?? '').substring(0, 5)} – ${(endTime ?? '').substring(0, 5)}';
}
