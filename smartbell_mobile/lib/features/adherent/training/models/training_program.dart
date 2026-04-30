class Exercise {
  final int id;
  final String name;
  final int sets;
  final int reps;
  final double? weight;
  final int? restSeconds;
  bool done;

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.restSeconds,
    this.done = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id:          (j['id'] ?? 0).toInt(),
    name:        j['name'] ?? j['exerciseName'] ?? 'Exercice',
    sets:        (j['sets'] ?? j['numberOfSets'] ?? 3).toInt(),
    reps:        (j['reps'] ?? j['numberOfReps'] ?? 10).toInt(),
    weight:      j['weight'] != null ? (j['weight'] as num).toDouble() : null,
    restSeconds: j['restSeconds'] != null ? (j['restSeconds'] as num).toInt() : 60,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'sets': sets, 'reps': reps,
    'weight': weight ?? 0, 'restSeconds': restSeconds ?? 60,
  };
}

class TrainingProgram {
  final int id;
  final String name;
  final String? description;
  final String? coachNote;
  final List<Exercise> exercises;

  TrainingProgram({
    required this.id,
    required this.name,
    this.description,
    this.coachNote,
    required this.exercises,
  });

  factory TrainingProgram.fromJson(Map<String, dynamic> j) {
    final rawEx = j['exercises'] ?? j['workouts'] ?? [];
    return TrainingProgram(
      id:          (j['id'] ?? 0).toInt(),
      name:        j['name'] ?? j['programName'] ?? 'Programme',
      description: j['description'],
      coachNote:   j['coachNote'] ?? j['notes'],
      exercises:   (rawEx as List).map((e) => Exercise.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'description': description, 'coachNote': coachNote,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}
