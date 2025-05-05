import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/auth_controller.dart';
import 'package:edu_track_project/screens/sub-pages/enable_notifications.dart';
import 'package:edu_track_project/screens/sub-pages/landing.dart';
import 'package:edu_track_project/screens/sub-pages/view_userprofile.dart';

class CSettings extends StatefulWidget {
  const CSettings({super.key});

  @override
  State<CSettings> createState() => _SettingsState();
}

class _SettingsState extends State<CSettings> {
  final AuthController _authController = AuthController();
  late Future<Map<String, dynamic>?> _userProfile;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _userProfile = _fetchUserProfile();
  }

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final profile = await _authController.getCurrentUser(_user.email!);
    return profile;
  }

  Future<void> _refreshUserProfile() async {
    setState(() {
      _userProfile = _fetchUserProfile();
    });
  }

  Future<void> _logout() async {
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userProfile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color.fromRGBO(29, 29, 29, 1),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
            body: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        } else if (snapshot.hasData) {
          Map<String, dynamic> userProfile = snapshot.data!;
          var motivationalQuoteReminders = userProfile['motivationalQuoteReminders'] ?? false;
          var studyTipsReminders = userProfile['studyTipReminders'] ?? false;

          return Scaffold(
            backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
            appBar: AppBar(
              title: const Text('Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: RefreshIndicator(
              onRefresh: _refreshUserProfile,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 20, 16.0, 0),
                child: ListView(
                  children: [
                    // Notifications Section
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications, color: Colors.white),
                      title: const Text('Notification Settings',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      trailing: const Icon(Icons.arrow_forward, color: Colors.white),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnableNotifications(
                              isMotivationalQuote: motivationalQuoteReminders,
                              isStudyTips: studyTipsReminders,
                            ),
                          ),
                        );
                        if (result == true) {
                          _refreshUserProfile();
                        }
                      },
                    ),
                    const Divider(
                      thickness: 2,
                      color: Color.fromARGB(255, 89, 88, 88),
                    ),
                    // Account Section
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.white),
                      title: const Text('View Profile',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      trailing: const Icon(Icons.arrow_forward, color: Colors.white),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ViewUserprofile(),
                          ),
                        );
                        if (result == true) {
                          _refreshUserProfile();
                        }
                      },
                    ),
                    const Divider(
                      thickness: 2,
                      color: Color.fromARGB(255, 89, 88, 88),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: const Text('Logout',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      onTap: _logout,
                    ),
                    const Divider(
                      thickness: 2,
                      color: Color.fromARGB(255, 89, 88, 88),
                    ),
                    const SizedBox(height: 20),
                    // App Info Section
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'About',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.white),
                      title: const Text('App Version',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      trailing: const Text('1.0.0',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ),
                    const Divider(
                      thickness: 2,
                      color: Color.fromARGB(255, 89, 88, 88),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const Scaffold(
            backgroundColor: Color.fromRGBO(29, 29, 29, 1),
            body: Center(
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      },
    );
  }
}