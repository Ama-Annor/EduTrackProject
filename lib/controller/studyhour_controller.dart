import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track_project/model/studyhour_model.dart';
import 'package:uuid/uuid.dart';

class StudyhourController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uuid = const Uuid();

  // Create a new study hour entry
  Future<bool> createStudyHour(Map<String, dynamic> data) async {
    try {
      // Generate a unique ID if not provided
      final String studyhourId = data['studyhour_id'] ?? uuid.v4();
      data['studyhour_id'] = studyhourId;

      // Store email in lowercase to ensure case-insensitive matching
      if (data.containsKey('userID') && data['userID'] != null) {
        data['userID'] = data['userID'].toString().trim().toLowerCase();
      }

      // Save to Firestore
      await _firestore.collection('studyHours').doc(studyhourId).set(data);
      print('Study hour created successfully: $studyhourId');
      return true;
    } catch (e) {
      print('Failed to create study hour: $e');
      return false;
    }
  }

  // Get one specific study hour by ID
  Future<StudyHour> getOneStudyhour(String studyhourId) async {
    try {
      final docSnapshot = await _firestore.collection('studyHours').doc(studyhourId).get();

      if (docSnapshot.exists) {
        return StudyHour.fromDocument(docSnapshot);
      } else {
        throw Exception('Study hour not found');
      }
    } catch (e) {
      print('Error getting study hour: $e');
      throw Exception('Failed to load study hour: $e');
    }
  }

  // Get all study hours for a specific user
  Future<List<StudyHour>> getAllStudyhours(String userId) async {
    try {
      print('Fetching study hours for user: $userId');

      // First, try exact match
      var querySnapshot = await _firestore
          .collection('studyHours')
          .where('userID', isEqualTo: userId.toLowerCase().trim())
          .get();

      // If no results, try case-insensitive approach by getting all and filtering
      if (querySnapshot.docs.isEmpty) {
        print('No exact matches found, trying case-insensitive search');
        querySnapshot = await _firestore.collection('studyHours').get();

        // Filter documents based on case-insensitive email comparison
        final filteredDocs = querySnapshot.docs.where((doc) {
          final docUserId = (doc.data()['userID'] as String?)?.toLowerCase().trim() ?? '';
          return docUserId == userId.toLowerCase().trim();
        }).toList();

        if (filteredDocs.isEmpty) {
          print('No study hours found for user: $userId');
          return [];
        }

        return filteredDocs.map((doc) => StudyHour.fromDocument(doc)).toList();
      }

      if (querySnapshot.docs.isEmpty) {
        print('No study hours found for user: $userId');
        return [];
      }

      print('Found ${querySnapshot.docs.length} study hours');
      return querySnapshot.docs.map((doc) => StudyHour.fromDocument(doc)).toList();
    } catch (e) {
      print('Error fetching study hours: $e');
      throw Exception('Failed to load study hours: $e');
    }
  }

  // Create a stream for real-time updates
  Stream<List<StudyHour>> getStudyHoursStream(String email) {
    return _firestore
        .collection('studyHours')
        .where('userID', isEqualTo: email.toLowerCase().trim())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyHour.fromDocument(doc))
            .toList());
  }

  // Update an existing study hour
  Future<bool> updateStudyhour(Map<String, dynamic> data, String studyhourId) async {
    try {
      await _firestore.collection('studyHours').doc(studyhourId).update(data);
      return true;
    } catch (e) {
      print('Error updating study hour: $e');
      return false;
    }
  }

  // Delete a study hour
  Future<bool> deleteStudyhour(String studyhourId) async {
    try {
      await _firestore.collection('studyHours').doc(studyhourId).delete();
      return true;
    } catch (e) {
      print('Error deleting study hour: $e');
      return false;
    }
  }
}