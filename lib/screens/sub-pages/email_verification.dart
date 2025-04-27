import 'dart:async';
import 'package:edu_track_project/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edu_track_project/screens/sub-pages/log_in.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isEmailVerified = false;
  bool isLoading = false;
  Timer? timer;
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    // Check if current user is available
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // No user is signed in, show error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user signed in'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(); // Go back
      });
      return;
    }

    // Send verification email
    _sendVerificationEmail();

    // Start periodic checking
    timer = Timer.periodic(
        const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _authController.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent'),
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkEmailVerified() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        timer?.cancel();
        return;
      }

      // Reload user to get fresh data
      await user.reload();
      // Get user again after reload
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified && mounted) {
        setState(() {
          isEmailVerified = true;
        });

        timer?.cancel();
        _showSuccessDialog();
      }
    } catch (e) {
      print("Error checking email verification: $e");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.check_circle,
                  color: Color(0xFF00BFA5), size: 50),
              SizedBox(height: 15),
              Text(
                'Success',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
            ],
          ),
          titleTextStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold),
          content: const Text(
              textAlign: TextAlign.center,
              'Congratulations! You have completed your registration.'),
          contentTextStyle: const TextStyle(
              color: Color.fromRGBO(66, 66, 66, 1),
              fontSize: 16,
              fontWeight: FontWeight.normal),
          actions: [
            CustomNormButton(
              text: 'Done',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Image.asset('assets/images/verification.png',
                  width: 170, height: 170, errorBuilder: (context, error, stackTrace) {
                    print("Error loading image: $error");
                    return Container(
                      width: 170,
                      height: 170,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.email_outlined, size: 80, color: Color(0xFF00BFA5)),
                    );
                  }),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verify your email address',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              textAlign: TextAlign.center,
              'A verification link has been sent to your email address. Please click on the link to verify your email address.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
            )
                : const Text(
              textAlign: TextAlign.center,
              'Waiting for verification...',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Didn\'t receive the email?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _sendVerificationEmail();
                  },
                  child: const Text(
                    'Resend email',
                    style: TextStyle(
                      color: Color(0xFF00BFA5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomNormButton(
              text: 'Check Verification Status',
              onPressed: () async {
                setState(() {
                  isLoading = true;
                });

                await _checkEmailVerified();

                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });

                  if (!isEmailVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email not verified yet. Please check your inbox.'),
                        backgroundColor: Color(0xFF00BFA5),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}