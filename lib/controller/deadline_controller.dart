import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edu_track_project/model/deadline_model.dart';
import 'package:uuid/uuid.dart';

class DeadlineController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new deadline
  Future<bool> createDeadline(Map<String, dynamic> data) async {
    try {
      // Generate a unique ID
      final String deadlineId = const Uuid().v4();

      // Get current user
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Add deadline_id to the data
      data['deadline_id'] = deadlineId;

      // Ensure userID is set as user.uid (instead of email)
      data['userID'] = user.uid;

      // Save to Firestore
      await _firestore.collection('deadlines').doc(deadlineId).set(data);

      return true;
    } catch (e) {
      print('Error creating deadline: $e');
      return false;
    }
  }

  // Get a specific deadline
  Future<Deadline> getOneDeadline(String deadlineId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('deadlines')
          .doc(deadlineId)
          .get();

      if (!doc.exists) {
        throw Exception('Deadline not found');
      }

      return Deadline.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting deadline: $e');
      rethrow;
    }
  }

  // Get all deadlines for a user (using email)
  Future<List<Deadline>> getAllDeadlines(String email) async {
    try {
      // First get the user's UID from their email
      User? currentUser = _auth.currentUser;
      String userId;

      if (currentUser != null && currentUser.email == email) {
        // If the current user is requesting their own deadlines
        userId = currentUser.uid;
      } else {
        // Otherwise, find the user by email
        QuerySnapshot userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          return []; // No user found
        }

        userId = userQuery.docs.first['uid'];
      }

      // Get all deadlines for this user
      QuerySnapshot snapshot = await _firestore
          .collection('deadlines')
          .where('userID', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => Deadline.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting deadlines: $e');
      return [];
    }
  }

  // Update a deadline
  Future<bool> updateDeadline(String deadlineId, Map<String, dynamic> data) async {
    try {
      // Check if current user is authorized
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the deadline to check ownership
      DocumentSnapshot deadlineDoc = await _firestore
          .collection('deadlines')
          .doc(deadlineId)
          .get();

      if (!deadlineDoc.exists) {
        throw Exception('Deadline not found');
      }

      Map<String, dynamic> deadlineData = deadlineDoc.data() as Map<String, dynamic>;
      if (deadlineData['userID'] != user.uid) {
        throw Exception('Unauthorized to update this deadline');
      }

      // Update deadline
      await _firestore
          .collection('deadlines')
          .doc(deadlineId)
          .update(data);

      return true;
    } catch (e) {
      print('Error updating deadline: $e');
      return false;
    }
  }

  // Delete a deadline
  Future<bool> deleteDeadline(String deadlineId) async {
    try {
      // Check if current user is authorized
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the deadline to check ownership
      DocumentSnapshot deadlineDoc = await _firestore
          .collection('deadlines')
          .doc(deadlineId)
          .get();

      if (!deadlineDoc.exists) {
        throw Exception('Deadline not found');
      }

      Map<String, dynamic> deadlineData = deadlineDoc.data() as Map<String, dynamic>;
      if (deadlineData['userID'] != user.uid) {
        throw Exception('Unauthorized to delete this deadline');
      }

      // Delete deadline
      await _firestore
          .collection('deadlines')
          .doc(deadlineId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting deadline: $e');
      return false;
    }
  }
}