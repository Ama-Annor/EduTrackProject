import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Use the global variable from main.dart
import 'package:edu_track_project/main.dart' show flutterLocalNotificationsPlugin;

class EnableNotifications extends StatefulWidget {
  final bool isMotivationalQuote;
  final bool isStudyTips;

  const EnableNotifications({
    super.key,
    this.isMotivationalQuote = false,
    this.isStudyTips = false,
  });

  @override
  State<EnableNotifications> createState() => _EnableNotificationsState();
}

class _EnableNotificationsState extends State<EnableNotifications> {
  late bool _motivationalQuote;
  late bool _studyTips;
  late User user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _motivationalQuote = widget.isMotivationalQuote;
    _studyTips = widget.isStudyTips;
    user = FirebaseAuth.instance.currentUser!;
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      String? fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.email).update({
          'fcmToken': fcmToken,
        });
      }
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _updateNotificationPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.email).update({
        'motivationalQuoteReminders': _motivationalQuote,
        'studyTipReminders': _studyTips,
      });
      print('Preferences updated successfully');

      // Only show snackbar if component is still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification preferences updated successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Send a test notification if either option is enabled
      if (_motivationalQuote) {
        await _sendTestMotivationalQuote();
      } else if (_studyTips) {
        await _sendTestStudyTip();
      }
    } catch (e) {
      print('Failed to update preferences: $e');

      // Only show snackbar if component is still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update preferences: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // Only update state if component is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendTestMotivationalQuote() async {
    try {
      // Try to fetch a quote from the API
      final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));

      String title = 'Daily Motivation';
      String message;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final quote = data[0]['q'];
        final author = data[0]['a'];
        message = '"$quote" - $author';
      } else {
        // Fallback quotes if API fails
        final fallbackQuotes = [
          '"The secret of getting ahead is getting started." - Mark Twain',
          '"It always seems impossible until it\'s done." - Nelson Mandela',
          '"Don\'t watch the clock; do what it does. Keep going." - Sam Levenson',
          '"Believe you can and you\'re halfway there." - Theodore Roosevelt',
          '"Success is not final, failure is not fatal: It is the courage to continue that counts." - Winston Churchill'
        ];
        message = fallbackQuotes[DateTime.now().second % fallbackQuotes.length];
      }

      await _showLocalNotification(title, message);
    } catch (e) {
      print('Error sending test motivational quote: $e');
      // Send a fallback quote
      await _showLocalNotification(
          'Daily Motivation',
          '"Believe you can and you\'re halfway there." - Theodore Roosevelt'
      );
    }
  }

  Future<void> _sendTestStudyTip() async {
    // Study tip database
    final List<String> studyTips = [
      'Try the Pomodoro Technique: 25 minutes of focused study followed by a 5-minute break.',
      'Review your notes within 24 hours of taking them to improve retention.',
      'Create mind maps to connect related concepts and improve understanding.',
      'Explain concepts out loud as if teaching someone else to enhance your understanding.',
      'Study in short, regular sessions rather than one long cramming session.',
    ];

    final tip = studyTips[DateTime.now().second % studyTips.length];

    await _showLocalNotification('Study Tip', tip);
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'edu_track_project_channel',
      'EduTrack Notifications',
      channelDescription: 'Notifications for EduTrack app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        title: const Text(
          'Notifications',
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
            Navigator.pop(context, true); // Return true to trigger refresh in settings.dart
          },
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00BFA5),
        ),
      )
          : Padding(
        padding: const EdgeInsets.fromLTRB(10, 30, 10, 20),
        child: Column(
          children: [
            // Description text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Enable notifications to receive daily motivational quotes and study tips to help you stay focused.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(
              thickness: 2,
              color: Color.fromARGB(255, 89, 88, 88),
            ),
            SwitchListTile(
              activeColor: const Color(0xFF00BFA5),
              title: const Text(
                'Receive notifications for motivational quotes',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              subtitle: const Text(
                'Daily inspirational quotes to keep you motivated',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              value: _motivationalQuote,
              onChanged: (bool value) {
                setState(() {
                  _motivationalQuote = value;
                });
                _updateNotificationPreferences();
              },
            ),
            const Divider(
              thickness: 2,
              color: Color.fromARGB(255, 89, 88, 88),
            ),
            SwitchListTile(
              activeColor: const Color(0xFF00BFA5),
              title: const Text(
                'Receive notifications for study tips',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              subtitle: const Text(
                'Helpful study techniques and strategies',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              value: _studyTips,
              onChanged: (bool value) {
                setState(() {
                  _studyTips = value;
                });
                _updateNotificationPreferences();
              },
            ),
            const Divider(
              thickness: 2,
              color: Color.fromARGB(255, 89, 88, 88),
            ),
            const SizedBox(height: 24),

            // Test notification button
            ElevatedButton.icon(
              onPressed: () async {
                if (_motivationalQuote) {
                  await _sendTestMotivationalQuote();
                } else if (_studyTips) {
                  await _sendTestStudyTip();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enable at least one notification type first',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notification_add),
              label: const Text('Send Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}