class MachineExercise {
  final int id;
  final String name;
  final String? muscleGroup;
  final String? difficultyLevel;

  const MachineExercise({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.difficultyLevel,
  });

  factory MachineExercise.fromJson(Map<String, dynamic> j) => MachineExercise(
        id:              (j['id'] ?? 0).toInt(),
        name:            j['name'] ?? j['exerciseName'] ?? '',
        muscleGroup:     j['muscleGroup'],
        difficultyLevel: j['difficultyLevel'],
      );
}

class Machine {
  final int id;
  final String name;
  final String? description;
  final String? location;
  final String status;
  final String? imageUrl;
  final String? tutorialUrl;
  final String? qrData;
  final List<MachineExercise> exercises;

  const Machine({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.status = 'AVAILABLE',
    this.imageUrl,
    this.tutorialUrl,
    this.qrData,
    this.exercises = const [],
  });

  factory Machine.fromJson(Map<String, dynamic> j) {
    final qrCode = j['qrCode'];
    final qrData = (qrCode is Map)
        ? (qrCode['qrData'] ?? qrCode['data'])?.toString()
        : j['qrData']?.toString();

    final rawEx = j['exercises'] ?? j['associatedExercises'] ?? [];

    return Machine(
      id:          (j['id'] ?? 0).toInt(),
      name:        j['name'] ?? '',
      description: j['description'],
      location:    j['location'],
      status:      j['status'] ?? 'AVAILABLE',
      imageUrl:    j['imageUrl'],
      tutorialUrl: j['tutorialUrl'],
      qrData:      qrData,
      exercises:   (rawEx as List)
          .map((e) => MachineExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
