class Macro {
  final double proteins;
  final double carbs;
  final double fats;

  const Macro({this.proteins = 0, this.carbs = 0, this.fats = 0});

  factory Macro.fromJson(Map<String, dynamic> j) => Macro(
    proteins: (j['proteins'] ?? j['protein'] ?? 0).toDouble(),
    carbs:    (j['carbs'] ?? j['carbohydrates'] ?? 0).toDouble(),
    fats:     (j['fats'] ?? j['fat'] ?? 0).toDouble(),
  );
}

class Meal {
  final int id;
  final String name;
  final String type; // BREAKFAST, LUNCH, DINNER, SNACK
  final double calories;
  final Macro macro;

  Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.macro,
  });

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
    id:       (j['id'] ?? 0).toInt(),
    name:     j['name'] ?? j['mealName'] ?? 'Repas',
    type:     j['type'] ?? j['mealType'] ?? 'LUNCH',
    calories: (j['calories'] ?? j['totalCalories'] ?? 0).toDouble(),
    macro:    j['macro'] != null
        ? Macro.fromJson(j['macro'])
        : Macro(proteins: (j['proteins'] ?? 0).toDouble(), carbs: (j['carbs'] ?? 0).toDouble(), fats: (j['fats'] ?? 0).toDouble()),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type, 'calories': calories,
    'proteins': macro.proteins, 'carbs': macro.carbs, 'fats': macro.fats,
  };

  String get typeLabel {
    switch (type.toUpperCase()) {
      case 'BREAKFAST': return 'Petit-déjeuner';
      case 'LUNCH':     return 'Déjeuner';
      case 'DINNER':    return 'Dîner';
      case 'SNACK':     return 'Collation';
      default:          return type;
    }
  }
}

class NutritionPlan {
  final int id;
  final String name;
  final double targetCalories;
  final List<Meal> meals;

  NutritionPlan({
    required this.id,
    required this.name,
    required this.targetCalories,
    required this.meals,
  });

  double get totalCalories => meals.fold(0, (s, m) => s + m.calories);

  factory NutritionPlan.fromJson(Map<String, dynamic> j) {
    final rawMeals = j['meals'] ?? [];
    return NutritionPlan(
      id:             (j['id'] ?? 0).toInt(),
      name:           j['name'] ?? j['planName'] ?? 'Plan nutritionnel',
      targetCalories: (j['targetCalories'] ?? j['dailyCalories'] ?? 2000).toDouble(),
      meals:          (rawMeals as List).map((e) => Meal.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'targetCalories': targetCalories,
    'meals': meals.map((m) => m.toJson()).toList(),
  };
}
