import 'package:edu_track_project/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final AuthService _authService = AuthService();

  // Get current user ID
  String? getCurrentUserId() {
    // Use Firebase Auth directly instead of accessing private field
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Get current user email
  String? getCurrentUserEmail() {
    // Use Firebase Auth directly instead of accessing private field
    return FirebaseAuth.instance.currentUser?.email;
  }

  Future<String?> checkPasswordSimilarity(
      String password, String confirmPassword) async {
    if (password == confirmPassword) {
      return null;
    }
    return 'passwords do not match';
  }

  Future<bool> isValidPassword(String password) async {
    return await _authService.isValidPassword(password);
  }

  Future<String> checkEmail(String email) async {
    int emailExists = await _authService.emailExists(email);
    if (emailExists == 0) {
      return 'does not exist';
    } else if (emailExists == 1) {
      return 'email exists';
    } else {
      return 'error';
    }
  }

  Future<bool> isEmailValid(String email) async {
    return await _authService.isValidEmail(email);
  }

  Future<String> checkUsername(String username) async {
    int usernameExists = await _authService.usernameExists(username);
    if (usernameExists == 0) {
      return 'does not exist';
    } else if (usernameExists == 1) {
      {
        return 'username exists';
      }
    } else {
      return 'error';
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser(String email) async {
    return await _authService.getUserInfo(email);
  }

  Future<bool> editUser(String email, Map<String, dynamic> updatedData) async{
    return await _authService.editUserInfo(email, updatedData);
  }

  Future<bool> isEmailVerified() async {
    return await _authService.isEmailVerified();
  }

  Future<Map<String, String>> registerWithEmailAndPassword(
      String email, String password) async {
    print("AuthController: Registering user with email $email");
    final result = await _authService.registerWithEmailAndPassword(email, password);
    print("AuthController: Registration result - $result");
    return result;
  }

  Future<Map<String, String>> signInWithEmailAndPassword(String email, String password) async {
    print("AuthController: Signing in user with email $email");
    final result = await _authService.signInWithEmailAndPassword(email, password);
    print("AuthController: Sign in result - $result");
    return result;
  }

  Future<void> saveUserInfo(String uid, String email, password, username, token) async {
    print("AuthController: Saving user info for UID $uid, email $email, username $username");
    await _authService.saveUserInfo(uid, email, password, username, token);
  }

  Future<void> sendEmailVerification() async {
    print("AuthController: Sending email verification");
    await _authService.emailVerification();
  }

  Future<void> setTimerForAutoRedirect() async {
    // Implementation if needed
  }

  Future<void> manullayCheckEmailVerificationStatus() async {
    // Implementation if needed
  }

  Future<void> signOut() async {
    print("AuthController: Signing out user");
    await _authService.signOut();
  }
}