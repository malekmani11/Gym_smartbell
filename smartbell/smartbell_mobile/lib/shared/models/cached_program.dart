import 'package:hive/hive.dart';

part 'cached_program.g.dart';

@HiveType(typeId: 0)
class CachedProgram extends HiveObject {
  @HiveField(0)
  int programId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String status;

  @HiveField(3)
  List<CachedExercise> exercises;

  CachedProgram({
    required this.programId,
    required this.name,
    required this.status,
    required this.exercises,
  });
}

@HiveType(typeId: 1)
class CachedExercise extends HiveObject {
  @HiveField(0)
  int exerciseId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? muscleGroup;

  @HiveField(3)
  int sets;

  @HiveField(4)
  int reps;

  @HiveField(5)
  int? restSeconds;

  @HiveField(6)
  int? dayNumber;

  @HiveField(7)
  int? orderIndex;

  @HiveField(8)
  String? imageUrl;

  CachedExercise({
    required this.exerciseId,
    required this.name,
    this.muscleGroup,
    required this.sets,
    required this.reps,
    this.restSeconds,
    this.dayNumber,
    this.orderIndex,
    this.imageUrl,
  });
}
