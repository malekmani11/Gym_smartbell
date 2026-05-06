// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_program.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedProgramAdapter extends TypeAdapter<CachedProgram> {
  @override
  final int typeId = 0;

  @override
  CachedProgram read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProgram(
      programId: fields[0] as int,
      name: fields[1] as String,
      status: fields[2] as String,
      exercises: (fields[3] as List).cast<CachedExercise>(),
    );
  }

  @override
  void write(BinaryWriter writer, CachedProgram obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.programId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.exercises);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedExerciseAdapter extends TypeAdapter<CachedExercise> {
  @override
  final int typeId = 1;

  @override
  CachedExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedExercise(
      exerciseId:  fields[0] as int,
      name:        fields[1] as String,
      muscleGroup: fields[2] as String?,
      sets:        fields[3] as int,
      reps:        fields[4] as int,
      restSeconds: fields[5] as int?,
      dayNumber:   fields[6] as int?,
      orderIndex:  fields[7] as int?,
      imageUrl:    fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedExercise obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.muscleGroup)
      ..writeByte(3)
      ..write(obj.sets)
      ..writeByte(4)
      ..write(obj.reps)
      ..writeByte(5)
      ..write(obj.restSeconds)
      ..writeByte(6)
      ..write(obj.dayNumber)
      ..writeByte(7)
      ..write(obj.orderIndex)
      ..writeByte(8)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
