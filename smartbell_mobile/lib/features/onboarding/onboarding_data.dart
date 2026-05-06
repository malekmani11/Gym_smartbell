import 'package:flutter/material.dart';

class OnboardingData {
  final String lottie;
  final String title;
  final String subtitle;
  final Color accentColor;

  OnboardingData({
    required this.lottie,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  static List<OnboardingData> onboardingList = [
    OnboardingData(
      lottie: 'assets/lottie/gym_workout.json',
      title: "Gérez votre salle\nenfin simplement",
      subtitle: "Membres, coachs, abonnements et paiements centralisés dans une seule app.",
      accentColor: const Color(0xFFEF9F27),
    ),
    OnboardingData(
      lottie: 'assets/lottie/nutrition.json',
      title: "Programmes\npersonnalisés",
      subtitle: "Entraînements et plans nutritionnels adaptés à chaque membre.",
      accentColor: const Color(0xFF1D9E75),
    ),
    OnboardingData(
      lottie: 'assets/lottie/ai_program.json',
      title: "L'IA génère\nvotre programme",
      subtitle: "Décrivez votre profil, Gemini AI crée votre programme sur mesure en secondes.",
      accentColor: const Color(0xFF534AB7),
    ),
  ];
}
