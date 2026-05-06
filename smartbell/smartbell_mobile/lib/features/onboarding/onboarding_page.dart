import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'onboarding_data.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Decorative Circle
        Positioned(
          top: -100,
          left: -100,
          right: -100,
          child: Container(
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.accentColor.withOpacity(0.15),
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Lottie Animation
              SizedBox(
                height: 280,
                child: Lottie.asset(
                  data.lottie,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              
              // Animated Title
              FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Animated Subtitle
              FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
