import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/screens/sub-pages/splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

// Add this global variable at the top of the file
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    await _initializeNotifications();
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Continue without Firebase for now
  }
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Handling a background message: ${message.messageId}");
  } catch (e) {
    print("Error in background handler: $e");
  }
}

Future<void> _initializeNotifications() async {
  // Android initialization
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS initialization
  final DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  // Initialize settings for all platforms
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  // Initialize the plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      print('Notification tapped: ${response.payload}');
    },
  );

  // Request permission (for iOS)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00BFA5), // Teal main color
        scaffoldBackgroundColor: const Color(0xFF1F2933), // Dark gray background
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00BFA5),
          secondary: const Color(0xFF00BFA5),
          surface: const Color(0xFF1F2933),
          background: const Color(0xFF1F2933),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}