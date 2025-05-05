import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/auth_controller.dart';
import 'package:edu_track_project/screens/sub-pages/edit_profile.dart';
import 'package:edu_track_project/screens/sub-pages/landing.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';

class ViewUserprofile extends StatefulWidget {
  const ViewUserprofile({super.key});

  @override
  State<ViewUserprofile> createState() => _ViewUserprofileState();
}

class _ViewUserprofileState extends State<ViewUserprofile> {
  late User _user;
  late Future<Map<String, dynamic>?> _userProfile;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _userProfile = _fetchUserProfile();
  }

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    return _authController.getCurrentUser(_user.email!);
  }

  Future<void> _onRefresh() async {
    final userProfile = await _fetchUserProfile();
    setState(() {
      _userProfile = Future.value(userProfile);
    });
  }

  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
          title: const Text(
            'Confirm Logout',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF00BFA5))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Color(0xFF00BFA5))),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await _authController.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      } catch (e) {
        print('Error logging out: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userProfile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        } else if (snapshot.hasData) {
          Map<String, dynamic> userProfile = snapshot.data!;
          usernameController.text = userProfile['username'] ?? '';
          emailController.text = userProfile['email'] ?? '';
          var picURL = userProfile['profilePicURL'] ?? '';

          return Scaffold(
            backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
            appBar: AppBar(
              backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
              title: const Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 30),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfile(
                          picURL: userProfile['profilePicURL'] ?? '',
                          username: userProfile['username'] ?? '',
                          email: userProfile['email'] ?? '',
                        ),
                      ),
                    );
                    if (result == true) {
                      _onRefresh();
                      Navigator.pop(context, true); // Return true to trigger refresh in settings.dart
                    }
                  },
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 40, 16.0, 0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      ClipOval(
                        child: picURL.isNotEmpty
                            ? Image.network(
                          picURL,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        )
                            : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      CustomTextField(
                        controller: usernameController,
                        labelText: 'Username',
                        hintText: 'Enter a valid username',
                        readOnly: true,
                        maxLenOfInput: 100,
                      ),
                      const SizedBox(height: 50),
                      CustomTextField(
                        controller: emailController,
                        labelText: 'Email',
                        hintText: 'Enter a valid email',
                        readOnly: true,
                        maxLenOfInput: 100,
                      ),
                      const SizedBox(height: 50),
                      CustomNormButton(
                        text: 'Log Out',
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
      },
    );
  }
}