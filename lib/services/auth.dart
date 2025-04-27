import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to check if Firebase is properly initialized
  bool get isFirebaseInitialized {
    try {
      FirebaseAuth.instance.app;
      return true;
    } catch (e) {
      print("Firebase not initialized: $e");
      return false;
    }
  }

  //check if username exists
  Future<int> usernameExists(String username) async {
    if (!isFirebaseInitialized) {
      return 0; // Return as if username doesn't exist
    }

    try {
      final result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      if (result.docs.isEmpty == true) {
        return 0;
      } else {
        return 1;
      }
    } catch (e) {
      print("Error checking if username exists: $e");
      return 2;
    }
  }

  //check if email exists
  Future<int> emailExists(String email) async {
    if (!isFirebaseInitialized) {
      return 0; // Return as if email doesn't exist
    }

    try {
      // More reliable way to check if email exists using Firebase Auth
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        return 1; // Email exists
      } else {
        return 0; // Email doesn't exist
      }
    } catch (e) {
      print("Error checking if email exists: $e");
      return 2;
    }
  }

  Future<bool> isEmailVerified() async {
    if (!isFirebaseInitialized) {
      return false; // Return as if email is not verified
    }

    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        // Reload user to get the most up-to-date information
        await user.reload();
        user = _firebaseAuth.currentUser; // Get the user again after reload
      }
      return user != null && user.emailVerified;
    } catch (e) {
      print("Error checking email verification: $e");
      return false;
    }
  }

  //check if email is a valid email
  Future<bool> isValidEmail(String email) async {
    // This doesn't need Firebase, so no need to check initialization
    const String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  //check if password is a valid password
  Future<bool> isValidPassword(String password) async {
    // This doesn't need Firebase, so no need to check initialization
    // Modified to match Firebase's minimum requirement (6 characters)
    return password.length >= 6;
  }

  Future<void> emailVerification() async {
    if (!isFirebaseInitialized) {
      print("Cannot send email verification: Firebase not initialized");
      return;
    }

    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print("Email verification sent to ${user.email}");
      } else {
        print("User is null or already verified");
      }
    } catch (e) {
      print("Error sending email verification: $e");
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(
            content: Text('Error sending verification email'),
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
      }
    }
  }

  //register with email and password
  Future<Map<String, String>> registerWithEmailAndPassword(
      String email, String password) async {
    if (!isFirebaseInitialized) {
      return {
        'status': 'error',
        'message': 'Firebase not initialized',
        'userId': ''
      };
    }

    try {
      print("Attempting to create user with email: $email");
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;
      print("User created successfully with UID: $uid");
      return {
        'status': 'success',
        'message': 'User registered successfully',
        'userId': uid
      };
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code}");
      if (e.code == 'weak-password') {
        return {
          'status': 'error',
          'message': 'The password provided is too weak.'
        };
      } else if (e.code == 'email-already-in-use') {
        return {
          'status': 'error',
          'message': 'The account already exists for that email.'
        };
      } else if (e.code == 'invalid-email') {
        return {
          'status': 'error',
          'message': 'The email address is not valid.'
        };
      }
      return {'status': 'error', 'message': 'An error occurred: ${e.code}'};
    } catch (e) {
      print("Error registering user: $e");
      return {'status': 'error', 'message': 'An error occurred: $e'};
    }
  }

  //save user info
  Future<void> saveUserInfo(
      String uid, String email, String password, String name, String token) async {
    if (!isFirebaseInitialized) {
      print("Cannot save user info: Firebase not initialized");
      return;
    }

    try {
      print("Saving user info for UID: $uid, Email: $email, Username: $name");
      // Save to users collection with email as document ID
      await _firestore.collection('users').doc(email).set({
        'email': email,
        'username': name,
        'motivationalQuoteReminders': false,
        'studyTipReminders': false,
        'academic_details': [],
        'profilePicURL': '',
        'uid': uid,
        'fcmToken': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("User info saved successfully");
    } catch (e) {
      print("Error saving user info: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String email) async {
    if (!isFirebaseInitialized) {
      print("Cannot get user info: Firebase not initialized");
      return null;
    }

    try {
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (result.docs.isNotEmpty) {
        return result.docs.first.data();
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting user info: $e");
      return null;
    }
  }

  Future<bool> editUserInfo(
      String email, Map<String, dynamic> updatedData) async {
    if (!isFirebaseInitialized) {
      print("Cannot edit user info: Firebase not initialized");
      return false;
    }

    try {
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (result.docs.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(result.docs.first.id)
            .update(updatedData);
        return true; // Update successful
      } else {
        print('User with the given email does not exist.');
        return false; // User not found
      }
    } catch (e) {
      print('Error updating user info: $e');
      return false; // Error occurred
    }
  }

  //sign in with email and password
  Future<Map<String, String>> signInWithEmailAndPassword(
      String email, String password) async {
    if (!isFirebaseInitialized) {
      return {
        'status': 'error',
        'message': 'Firebase not initialized',
        'userId': ''
      };
    }

    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      // Check if email is verified before allowing sign in
      if (user != null && !user.emailVerified) {
        return {
          'status': 'error',
          'message': 'Please verify your email before signing in',
          'userId': user.uid
        };
      }

      return {
        'status': 'success',
        'message': 'User signed in successfully',
        'userId': user!.uid,
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {'status': 'error', 'message': 'No user found.'};
      } else if (e.code == 'wrong-password') {
        return {
          'status': 'error',
          'message': 'Wrong password provided for that user.'
        };
      } else {
        return {'status': 'error', 'message': 'An error occurred: ${e.code}'};
      }
    } catch (e) {
      print("Error signing in: $e");
      return {'status': 'error', 'message': 'An error occurred: $e'};
    }
  }

  //sign out
  Future signOut() async {
    if (!isFirebaseInitialized) {
      print("Cannot sign out: Firebase not initialized");
      return null;
    }

    try {
      return await _firebaseAuth.signOut();
    } catch (e) {
      print("Error signing out: $e");
      return null;
    }
  }
}