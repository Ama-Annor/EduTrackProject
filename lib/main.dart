import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/screens/sub-pages/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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