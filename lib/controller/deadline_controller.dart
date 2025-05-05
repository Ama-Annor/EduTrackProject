import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track_project/model/deadline_model.dart';
import 'package:uuid/uuid.dart';

class DeadlineController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new deadline
  Future<bool> createDeadline(Map<String, dynamic> data) async {
    try {
      // Generate a unique ID for the deadline
      String deadlineId = _uuid.v4();
      print('Creating deadline with ID: $deadlineId');

      // Add the deadline_id to the data
      data['deadline_id'] = deadlineId;

      // Ensure userID is not null or empty
      if (data['userID'] == null || data['userID'].toString().isEmpty) {
        print('Warning: userID is null or empty');
        return false;
      }

      // Normalize the email format
      String userID = data['userID'] as String;
      data['userID'] = userID.trim();

      print('Full deadline data to save: $data');

      // Create the document in Firestore
      await _firestore.collection('deadlines').doc(deadlineId).set(data);
      print('Deadline successfully saved to Firestore');

      return true;
    } catch (e) {
      print('Error creating deadline: $e');
      return false;
    }
  }

  // Get a specific deadline by ID
  Future<Deadline> getOneDeadline(String deadlineId) async {
    try {
      final DocumentSnapshot doc =
      await _firestore.collection('deadlines').doc(deadlineId).get();

      if (doc.exists) {
        return Deadline.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Deadline not found');
      }
    } catch (e) {
      throw Exception('Failed to get deadline: $e');
    }
  }

  // Get all deadlines for a specific user
  Future<List<Deadline>> getAllDeadlines(String userEmail) async {
    try {
      print('Fetching deadlines for user: $userEmail');

      // First try with exact match
      QuerySnapshot querySnapshot = await _firestore
          .collection('deadlines')
          .where('userID', isEqualTo: userEmail)
          .get();

      print('Found ${querySnapshot.docs.length} deadlines with exact match');

      if (querySnapshot.docs.isNotEmpty) {
        // If we got here, we have results with the exact email
        final deadlines = querySnapshot.docs
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing document: ${doc.id}, data: $data');
          return Deadline.fromMap(data);
        })
            .toList();

        print('Processed ${deadlines.length} deadlines successfully');
        return deadlines;
      }

      // If we're here, no results with exact match, try getting all deadlines
      print('No results with exact email match. Fetching all deadlines...');
      querySnapshot = await _firestore.collection('deadlines').get();

      print('Total deadlines found: ${querySnapshot.docs.length}');

      // Loop through all deadlines and print userIDs for debugging
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String docUserId = (data['userID'] as String?) ?? 'null';
        print('Deadline ${doc.id} has userID: "$docUserId", looking for: "$userEmail"');
      }

      // Convert input email to lowercase for comparison
      final String normalizedEmail = userEmail.trim().toLowerCase();
      print('Normalized email for comparison: $normalizedEmail');

      // Filter locally for case-insensitive match
      final docs = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final String docEmail = (data['userID'] as String?) ?? '';
        final bool matches = docEmail.trim().toLowerCase() == normalizedEmail;
        print('Comparing "${docEmail.trim().toLowerCase()}" with "$normalizedEmail" = $matches');
        return matches;
      }).toList();

      print('Found ${docs.length} deadlines with case-insensitive match');

      final deadlines = docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Deadline.fromMap(data);
      })
          .toList();

      print('Processed ${deadlines.length} deadlines successfully');
      return deadlines;
    } catch (e) {
      print('Error getting deadlines: $e');
      throw Exception('Failed to load deadlines: $e');
    }
  }

  // Update an existing deadline
  Future<bool> updateDealine(Map<String, dynamic> data, String deadlineId) async {
    try {
      await _firestore.collection('deadlines').doc(deadlineId).update(data);
      return true;
    } catch (e) {
      print('Error updating deadline: $e');
      return false;
    }
  }

  // Delete a deadline
  Future<bool> deleteDeadline(String deadlineId) async {
    try {
      await _firestore.collection('deadlines').doc(deadlineId).delete();
      return true;
    } catch (e) {
      print('Error deleting deadline: $e');
      return false;
    }
  }

  // Debug method to list all deadlines
  Future<void> debugListAllDeadlines() async {
    try {
      print('===== DEBUGGING: Listing all deadlines in Firestore =====');

      final QuerySnapshot querySnapshot = await _firestore
          .collection('deadlines')
          .get();

      print('Total deadlines in database: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('No deadlines found in database.');
        return;
      }

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('------------------------------------');
        print('Deadline ID: ${doc.id}');
        print('Title: ${data['title']}');
        print('Description: ${data['description']}');
        print('Due Date: ${data['dueDate']}');
        print('User ID: ${data['userID']}');
        print('------------------------------------');
      }

      print('===== END DEBUGGING =====');
    } catch (e) {
      print('Error listing all deadlines: $e');
    }
  }
}