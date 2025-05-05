import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track_project/model/schedule_model.dart';
import 'package:uuid/uuid.dart';

class ScheduleController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new schedule
  Future<bool> createSchedule(Map<String, dynamic> data) async {
    try {
      // Generate a unique ID for the schedule
      String scheduleId = _uuid.v4();

      // Add the schedule_id to the data
      data['schedule_id'] = scheduleId;

      // Ensure userID is not null or empty
      if (data['userID'] == null || data['userID'].toString().isEmpty) {
        print('Warning: userID is null or empty');
        return false;
      }

      // Normalize the email format
      String userID = data['userID'] as String;
      data['userID'] = userID.trim();

      print('Full schedule data to save: $data');

      // Create the document in Firestore
      await _firestore.collection('schedules').doc(scheduleId).set(data);
      print('Schedule successfully saved to Firestore');

      return true;
    } catch (e) {
      print('Error creating schedule: $e');
      return false;
    }
  }

  // Get a specific schedule by ID
  Future<Schedule> getOneSchedule(String scheduleId) async {
    try {
      final DocumentSnapshot doc =
      await _firestore.collection('schedules').doc(scheduleId).get();

      if (doc.exists) {
        return Schedule.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Schedule not found');
      }
    } catch (e) {
      throw Exception('Failed to get schedule: $e');
    }
  }

  // Get all schedules for a specific user
  Future<List<Schedule>> getAllSchedules(String userEmail) async {
    try {
      print('Fetching schedules for user: $userEmail');

      // First try with exact match
      QuerySnapshot querySnapshot = await _firestore
          .collection('schedules')
          .where('userID', isEqualTo: userEmail)
          .get();

      print('Found ${querySnapshot.docs.length} schedules with exact match');

      if (querySnapshot.docs.isNotEmpty) {
        // If we got here, we have results with the exact email
        final schedules = querySnapshot.docs
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing document: ${doc.id}, data: $data');
          return Schedule.fromMap(data);
        })
            .toList();

        print('Processed ${schedules.length} schedules successfully');
        return schedules;
      }

      // If we're here, no results with exact match, try getting all schedules
      print('No results with exact email match. Fetching all schedules...');
      querySnapshot = await _firestore.collection('schedules').get();

      print('Total schedules found: ${querySnapshot.docs.length}');

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

      print('Found ${docs.length} schedules with case-insensitive match');

      final schedules = docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Schedule.fromMap(data);
      })
          .toList();

      print('Processed ${schedules.length} schedules successfully');
      return schedules;
    } catch (e) {
      print('Error getting schedules: $e');
      throw Exception('Failed to load schedules: $e');
    }
  }

  // Update an existing schedule
  Future<bool> updateSchedule(Map<String, dynamic> data, String scheduleId) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).update(data);
      return true;
    } catch (e) {
      print('Error updating schedule: $e');
      return false;
    }
  }

  // Delete a schedule
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).delete();
      return true;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }
}