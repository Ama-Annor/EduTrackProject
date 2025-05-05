import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/auth_controller.dart';
import 'package:edu_track_project/screens/sub-pages/email_verification.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Add these to control password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _emailError;
  String? _passwordError;
  String? _passwordConfirmError;
  String? _usernameError;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _validateEmail();
      }
    });

    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        _validateUsername();
      }
    });
    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus) {
        _validatePassword();
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
    _confirmPasswordFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
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

    final badMailFormat = await _authController.isEmailValid(email);

    if (badMailFormat == false) {
      setState(() {
        _emailError = 'Your email does not meet the right requirements';
      });
      return;
    }

    final emailError = await _authController.checkEmail(email);

    setState(() {
      _emailError =
      emailError == 'email exists' ? 'Email already exists' : null;
    });
  }

  Future<void> _validateUsername() async {
    final username = _usernameController.text.trim();
    final usernameError = await _authController.checkUsername(username);

    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username cannot be empty';
      });
      return;
    }

    setState(() {
      _usernameError =
      usernameError == 'username exists' ? 'Username already exists' : null;
    });
  }

  void _validatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final badPasswordFormat = await _authController.isValidPassword(password);

    if (badPasswordFormat == false) {
      setState(() {
        _passwordError = 'Your password is too weak';
      });
      return;
    }

    if (password.isEmpty && confirmPassword.isEmpty) {
      setState(() {
        _passwordError = 'Password cannot be empty';
        _passwordConfirmError = 'Password cannot be empty';
        return;
      });
    } else if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password cannot be empty';
        _passwordConfirmError = null; // Clear the confirmPassword error if any
        return;
      });
    } else if (confirmPassword.isEmpty) {
      setState(() {
        _passwordError = null; // Clear the password error if any
        _passwordConfirmError = 'Password cannot be empty';
        return;
      });
    } else if (password != confirmPassword) {
      setState(() {
        _passwordError = 'Passwords do not match';
        _passwordConfirmError = 'Passwords do not match';
        return;
      });
    } else {
      // Clear errors if both fields are non-empty
      setState(() {
        _passwordError = null;
        _passwordConfirmError = null;
      });
      return;
    }
  }

  Future<void> registerUser(context) async {
    setState(() {
      _validateEmail();
      _validateUsername();
      _validatePassword();
    });

    if (_emailError == null &&
        _passwordError == null &&
        _usernameError == null &&
        _passwordConfirmError == null) {
      var result = await _authController.registerWithEmailAndPassword(
          _emailController.text.trim(), _passwordController.text.trim());
      if (result['message'] == 'User registered successfully') {
        var uid = result['userId'];
        String? token = await FirebaseMessaging.instance.getToken();
        _authController.saveUserInfo(uid!, _emailController.text.trim(),
            _passwordController.text.trim(), _usernameController.text.trim(), '');
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const EmailVerificationPage();
        }));
      } else if (result['message'] == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The provided password is too weak.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (result['message'] ==
          'The account already exists for that email.') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An account already exists for that email.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An error ocurred. Please try again later.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {}
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
        padding: const EdgeInsets.fromLTRB(25.0, 16.0, 25.0, 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Create an account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              CustomTextField(
                controller: _usernameController,
                labelText: 'Username',
                hintText: 'Enter username',
                errorText: _usernameError,
                keyboardType: TextInputType.name,
                focusNode: _usernameFocusNode,
                maxLenOfInput: 20,
              ),
              const SizedBox(height: 25),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Enter email address',
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocusNode,
                maxLenOfInput: 50,
              ),
              const SizedBox(height: 25),

              // Modified password field with toggle button
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Password must be at least 8 characters long',
                    errorText: _passwordError,
                    obscureText: _obscurePassword, // Use the state variable
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: _passwordFocusNode,
                    maxLenOfInput: 20,
                  ),
                  Positioned(
                    right: 10,
                    child: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Modified confirm password field with toggle button
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm password',
                    hintText: 'Re-enter password',
                    errorText: _passwordConfirmError,
                    obscureText: _obscureConfirmPassword, // Use the state variable
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: _confirmPasswordFocusNode,
                    maxLenOfInput: 20,
                  ),
                  Positioned(
                    right: 10,
                    child: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 70),
              CustomNormButton(
                text: 'Sign Up',
                onPressed: () {
                  registerUser(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}