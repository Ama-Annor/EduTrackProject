import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:edu_track_project/screens/sub-pages/landing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool showSecondText = false;

  @override
  void initState() {
    super.initState();
    // Ensure the second text appears after 2 seconds
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        showSecondText = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2933),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Edu Track',
                  textStyle: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BFA5),
                  ),
                  speed: const Duration(milliseconds: 400),
                ),
              ],
              isRepeatingAnimation: false,
              onFinished: () {
                // Ensure second text appears after the first one finishes
                Future.delayed(const Duration(milliseconds: 200), () {
                  setState(() {
                    showSecondText = true;
                  });
                });
              },
            ),
            const SizedBox(height: 5),
            if (showSecondText)
              AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText(
                    'Your education, on track',
                    textStyle: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                    ),
                    duration: const Duration(milliseconds: 2000),
                  ),
                ],
                isRepeatingAnimation: false,
                onFinished: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LandingPage(),
                     ),
                   );
                },
              ),
          ],
        ),
      ),

    );
  }
}