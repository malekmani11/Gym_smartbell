class AiTrainingRequest {
  final double height; // cm
  final double weight; // kg
  final int age;
  final String goal;        // PERTE_DE_POIDS, PRISE_DE_MUSCLE, ENDURANCE, FORME_GENERALE
  final String level;       // DEBUTANT, INTERMEDIAIRE, AVANCE
  final int sessionsPerWeek;
  final String? equipment;  // SALLE, MAISON, SANS_EQUIPEMENT
  final String? injuries;   // blessures éventuelles

  const AiTrainingRequest({
    required this.height,
    required this.weight,
    required this.age,
    required this.goal,
    required this.level,
    required this.sessionsPerWeek,
    this.equipment = 'SALLE',
    this.injuries,
  });

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Insuffisance pondérale';
    if (bmi < 25)   return 'Poids normal';
    if (bmi < 30)   return 'Surpoids';
    return 'Obésité';
  }

  Map<String, dynamic> toJson() => {
    'height': height,
    'weight': weight,
    'age': age,
    'goal': goal,
    'level': level,
    'sessionsPerWeek': sessionsPerWeek,
    'equipment': equipment,
    if (injuries != null && injuries!.isNotEmpty) 'injuries': injuries,
  };

  /// Prompt envoyé à l'IA
  String toPrompt() {
    final goalLabel = {
      'PERTE_DE_POIDS':   'perte de poids',
      'PRISE_DE_MUSCLE':  'prise de muscle (hypertrophie)',
      'ENDURANCE':        'amélioration de l\'endurance',
      'FORME_GENERALE':   'remise en forme générale',
    }[goal] ?? goal;

    final levelLabel = {
      'DEBUTANT':      'débutant',
      'INTERMEDIAIRE': 'intermédiaire',
      'AVANCE':        'avancé',
    }[level] ?? level;

    final equipLabel = {
      'SALLE':              'salle de sport complète',
      'MAISON':             'à domicile avec équipement léger',
      'SANS_EQUIPEMENT':    'sans équipement (poids du corps uniquement)',
    }[equipment] ?? 'salle de sport';

    return '''
Tu es un coach sportif expert. Génère un programme d'entraînement personnalisé en JSON uniquement.

Profil de l'adhérent :
- Taille : ${height.toInt()} cm
- Poids : ${weight.toInt()} kg
- IMC : ${bmi.toStringAsFixed(1)} ($bmiCategory)
- Âge : $age ans
- Objectif : $goalLabel
- Niveau : $levelLabel
- Équipement : $equipLabel
- Séances par semaine : $sessionsPerWeek
${injuries != null && injuries!.isNotEmpty ? '- Blessures/restrictions : $injuries' : ''}

Retourne UNIQUEMENT ce JSON valide, sans explication :
{
  "name": "Nom du programme",
  "description": "Description courte",
  "coachNote": "Conseil personnalisé du coach",
  "exercises": [
    {
      "id": 1,
      "name": "Nom de l'exercice",
      "sets": 3,
      "reps": 12,
      "weight": 0,
      "restSeconds": 60
    }
  ]
}

Inclure entre 6 et 10 exercices adaptés au profil. Pour weight, mettre 0 si poids du corps.
''';
  }
}
