// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User notification settings: ${settings.authorizationStatus}');

    // Configure local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Get and store FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
      print('FCM Token: $token');
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

    // Handle received messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when notification opens the app from terminated state
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);

    // Handle when notification opens the app from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap based on notification data
    print('Notification tapped: ${response.payload}');
    // You could navigate to a specific screen based on the payload
  }

  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save token to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .update({
        'fcmToken': token,
        'platform': _getPlatform(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      // Save to shared preferences as well for quick local access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }
  }

  String _getPlatform() {
    // Simple platform detection
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling foreground message: ${message.messageId}');

    // Show a local notification
    await _showLocalNotification(
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _handleInitialMessage(RemoteMessage? message) async {
    if (message != null) {
      print('App opened from terminated state by notification: ${message.messageId}');
      // Handle navigation based on notification data
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from background state by notification: ${message.messageId}');
    // Handle navigation based on notification data
  }

  Future<void> _showLocalNotification(
      String title,
      String body, {
        String? payload,
      }) async {
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

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Method to enable or disable notifications in user preferences
  Future<void> updateNotificationPreferences({
    required bool motivationalQuotes,
    required bool studyTips,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .update({
        'motivationalQuoteReminders': motivationalQuotes,
        'studyTipReminders': studyTips,
      });
    }
  }

  // Retrieve user's notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return {
          'motivationalQuoteReminders': data?['motivationalQuoteReminders'] ?? false,
          'studyTipReminders': data?['studyTipReminders'] ?? false,
        };
      }
    }
    return {
      'motivationalQuoteReminders': false,
      'studyTipReminders': false,
    };
  }

  // Method to manually trigger a local notification for testing
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      'Test Notification',
      'This is a test notification from EduTrack!',
      payload: jsonEncode({'type': 'test'}),
    );
  }

  // Send Motivational Quote notification
  Future<void> fetchAndSendMotivationalQuote() async {
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final quote = data[0]['q'];
        final author = data[0]['a'];

        await _showLocalNotification(
          'Daily Motivational Quote',
          '"$quote" - $author',
          payload: jsonEncode({'type': 'motivational_quote'}),
        );
      }
    } catch (e) {
      print('Error fetching motivational quote: $e');
      await _showLocalNotification(
        'Daily Motivational Quote',
        'Stay focused and keep pushing forward!',
        payload: jsonEncode({'type': 'motivational_quote'}),
      );
    }
  }

  // Send Study Tip notification
  Future<void> fetchAndSendStudyTip() async {
    final List<String> studyTips = [
      'Try the Pomodoro Technique: 25 minutes of focused study followed by a 5-minute break.',
      'Review your notes within 24 hours of taking them to improve retention.',
      'Create mind maps to connect related concepts and improve understanding.',
      'Explain concepts out loud as if teaching someone else to enhance your understanding.',
      'Study in short, regular sessions rather than one long cramming session.',
      'Stay hydrated! Drinking water improves brain function and concentration.',
      'Get enough sleep. Your brain processes and stores information during sleep.',
      'Change study locations occasionally to improve memory and concentration.',
      'Use active recall instead of just rereading material. Test yourself frequently.',
      'Take short breaks to walk or stretch to maintain focus and energy.',
    ];

    final tip = studyTips[DateTime.now().day % studyTips.length];

    await _showLocalNotification(
      'Daily Study Tip',
      tip,
      payload: jsonEncode({'type': 'study_tip'}),
    );
  }
}