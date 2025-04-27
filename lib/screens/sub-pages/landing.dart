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
              Image.asset('assets/images/landing.png'),
              const SizedBox(height: 130),
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
            ],),
        ),
      ),
    );
  }
}