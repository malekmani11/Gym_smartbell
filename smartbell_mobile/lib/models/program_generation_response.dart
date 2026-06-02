import '../features/adherent/training/models/training_program.dart';

class SeanceAi {
  final String       nom;
  final List<Exercise> exercices;

  const SeanceAi({required this.nom, required this.exercices});

  factory SeanceAi.fromJson(Map<String, dynamic> j) => SeanceAi(
    nom      : j['nom'] as String? ?? '',
    exercices: ((j['exercices'] ?? j['exercises'] ?? []) as List)
        .asMap()
        .entries
        .map((e) => Exercise.fromJson({...e.value as Map<String, dynamic>, 'id': e.key + 1}))
        .toList(),
  );
}

class ProgramGenerationResponse {
  final List<SeanceAi> seances;
  final String         noteCoach;
  final String         typeProgramme;
  final int            intensite;
  final String         split;
  final double         imc;
  final String         imcCategorie;

  const ProgramGenerationResponse({
    required this.seances,
    required this.noteCoach,
    required this.typeProgramme,
    required this.intensite,
    required this.split,
    required this.imc,
    required this.imcCategorie,
  });

  factory ProgramGenerationResponse.fromJson(Map<String, dynamic> json) =>
      ProgramGenerationResponse(
        seances      : ((json['seances'] ?? []) as List)
            .map((s) => SeanceAi.fromJson(s as Map<String, dynamic>))
            .toList(),
        noteCoach    : json['note_coach']                              as String? ?? '',
        typeProgramme: (json['typeProgramme'] ?? json['type_programme']) as String? ?? '',
        intensite    : (json['intensite']    ?? 0).toInt(),
        split        : json['split']                                   as String? ?? '',
        imc          : (json['imc']          ?? 0.0).toDouble(),
        imcCategorie : (json['imcCategorie'] ?? json['imc_categorie']) as String? ?? '',
      );
}
