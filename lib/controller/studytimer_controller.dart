import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track_project/model/studytimer_model.dart';
import 'package:uuid/uuid.dart';

class StudytimerController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uuid = const Uuid();

  // Create a new study timer entry
  Future<bool> createStudytimer(Map<String, dynamic> data) async {
    try {
      // Add current date if not provided
      if (!data.containsKey('date') || data['date'] == null) {
        data['date'] = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
      }

      // Generate a unique ID if not provided
      final String studytimerId = data['studytimer_id'] ?? uuid.v4();
      data['studytimer_id'] = studytimerId;

      // Store email in lowercase to ensure case-insensitive matching
      if (data.containsKey('userID') && data['userID'] != null) {
        data['userID'] = data['userID'].toString().trim().toLowerCase();
      }

      // Save to Firestore
      await _firestore.collection('studyTimers').doc(studytimerId).set(data);
      print('Study timer created successfully: $studytimerId');
      return true;
    } catch (e) {
      print('Failed to create study timer: $e');
      return false;
    }
  }

  // Get one specific study timer by ID
  Future<Studytimer> getOneStudytimer(String studytimerId) async {
    try {
      final docSnapshot = await _firestore.collection('studyTimers').doc(studytimerId).get();

      if (docSnapshot.exists) {
        return Studytimer.fromDocument(docSnapshot);
      } else {
        throw Exception('Study timer not found');
      }
    } catch (e) {
      print('Error getting study timer: $e');
      throw Exception('Failed to load study timer: $e');
    }
  }

  // Get all study timers for a specific user
  Future<List<Studytimer>> getAllStudytimers(String userId) async {
    try {
      print('Fetching study timers for user: $userId');

      // First, try exact match
      var querySnapshot = await _firestore
          .collection('studyTimers')
          .where('userID', isEqualTo: userId.toLowerCase().trim())
          .get();

      // If no results, try case-insensitive approach by getting all and filtering
      if (querySnapshot.docs.isEmpty) {
        print('No exact matches found, trying case-insensitive search');
        querySnapshot = await _firestore.collection('studyTimers').get();

        // Filter documents based on case-insensitive email comparison
        final filteredDocs = querySnapshot.docs.where((doc) {
          final docUserId = (doc.data()['userID'] as String?)?.toLowerCase().trim() ?? '';
          return docUserId == userId.toLowerCase().trim();
        }).toList();

        if (filteredDocs.isEmpty) {
          print('No study timers found for user: $userId');
          return [];
        }

        return filteredDocs.map((doc) => Studytimer.fromDocument(doc)).toList();
      }

      if (querySnapshot.docs.isEmpty) {
        print('No study timers found for user: $userId');
        return [];
      }

      print('Found ${querySnapshot.docs.length} study timers');
      return querySnapshot.docs.map((doc) => Studytimer.fromDocument(doc)).toList();
    } catch (e) {
      print('Error fetching study timers: $e');
      throw Exception('Failed to load study timers: $e');
    }
  }

  // Update an existing study timer
  Future<bool> updateStudytimer(Map<String, dynamic> data, String studytimerId) async {
    try {
      await _firestore.collection('studyTimers').doc(studytimerId).update(data);
      return true;
    } catch (e) {
      print('Error updating study timer: $e');
      return false;
    }
  }

  // Delete a study timer
  Future<bool> deleteStudytimer(String studytimerId) async {
    try {
      await _firestore.collection('studyTimers').doc(studytimerId).delete();
      return true;
    } catch (e) {
      print('Error deleting study timer: $e');
      return false;
    }
  }
}