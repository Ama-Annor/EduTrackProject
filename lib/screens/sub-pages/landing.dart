import 'package:flutter/material.dart';
import 'package:edu_track_project/screens/sub-pages/log_in.dart';
import 'package:edu_track_project/screens/sub-pages/sign_up.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2933),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/branding section
              Column(
                children: [
                  // Replace image with an icon
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school, // Education-themed icon
                      size: 100,
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Edu Track',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your education, on track',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
              CustomNormButton(
                text: 'Log In',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                },
              ),
              const SizedBox(height: 30),
              CustomNormButton(
                text: 'Sign Up',
                textColor: const Color(0xFF00BFA5),
                buttonColor: Colors.white,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}