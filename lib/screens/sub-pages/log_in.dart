import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/auth_controller.dart';
import 'package:edu_track_project/screens/sub-pages/sign_up.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';
import 'package:edu_track_project/screens/widgets/bottom_nav_bar.dart'; // Import CustomBottomNav

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _validateEmail();
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _validatePassword();
      }
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _validateEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email cannot be empty';
      });
      return;
    }
  }

  void _validatePassword() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password cannot be empty';
        return;
      });
    } else {
      // Clear errors if both fields are non-empty
      setState(() {
        _passwordError = null;
      });
      return;
    }
  }

  Future<void> signIn(context) async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    setState(() {
      _validateEmail();
      _validatePassword();
    });

    if (_emailError == null && _passwordError == null) {
      try {
        var result = await _authController.signInWithEmailAndPassword(
            _emailController.text, _passwordController.text);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (result['status'] == 'success') {
          // Navigate to the CustomBottomNav instead of Dashboard directly
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomBottomNav(email: _emailController.text),
            ),
          );
        } else if (result['message'] == 'No user found.') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No user found.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF00BFA5),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (result['message'] == 'Wrong password provided for that user.') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Wrong password provided for that user.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF00BFA5),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (result['message'] == 'Please verify your email before signing in') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please verify your email before signing in.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF00BFA5),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login error: ${result['message']}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF00BFA5),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'An error occurred: $e',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF00BFA5),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 140),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Enter email address',
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocusNode,
                maxLenOfInput: 50,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter password',
                errorText: _passwordError,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                focusNode: _passwordFocusNode,
                maxLenOfInput: 20,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
              )
                  : CustomNormButton(
                text: 'Log In',
                onPressed: () {
                  signIn(context);
                },
              ),
              const SizedBox(height: 150),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Don\'t have an account yet?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()));
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF00BFA5),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}