import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track_project/model/note_model.dart';
import 'package:uuid/uuid.dart';

class NoteController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new note
  Future<bool> createNote(Map<String, dynamic> data) async {
    try {
      // Generate a unique ID for the note
      String noteId = _uuid.v4();

      // Add the note_id to the data
      data['note_id'] = noteId;

      // Ensure userID is not null or empty
      if (data['userID'] == null || data['userID'].toString().isEmpty) {
        print('Warning: userID is null or empty');
        return false;
      }

      // Normalize the email format
      String userID = data['userID'] as String;
      data['userID'] = userID.trim();

      print('Full note data to save: $data');

      // Create the document in Firestore
      await _firestore.collection('notes').doc(noteId).set(data);
      print('Note successfully saved to Firestore');

      return true;
    } catch (e) {
      print('Error creating note: $e');
      return false;
    }
  }

  // Get a specific note by ID
  Future<Note> getOneNote(String noteId) async {
    try {
      final DocumentSnapshot doc =
      await _firestore.collection('notes').doc(noteId).get();

      if (doc.exists) {
        return Note.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Note not found');
      }
    } catch (e) {
      throw Exception('Failed to get note: $e');
    }
  }

  // Get all notes for a specific user
  Future<List<Note>> getAllNotes(String userEmail) async {
    try {
      print('Fetching notes for user: $userEmail');

      // First try with exact match
      QuerySnapshot querySnapshot = await _firestore
          .collection('notes')
          .where('userID', isEqualTo: userEmail)
          .get();

      print('Found ${querySnapshot.docs.length} notes with exact match');

      if (querySnapshot.docs.isNotEmpty) {
        // If we got here, we have results with the exact email
        final notes = querySnapshot.docs
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing document: ${doc.id}, data: $data');
          return Note.fromMap(data);
        })
            .toList();

        // Sort by lastModified (newest first)
        notes.sort((a, b) => DateTime.parse(b.lastModified).compareTo(DateTime.parse(a.lastModified)));

        print('Processed ${notes.length} notes successfully');
        return notes;
      }

      // If we're here, no results with exact match, try getting all notes
      print('No results with exact email match. Fetching all notes...');
      querySnapshot = await _firestore.collection('notes').get();

      print('Total notes found: ${querySnapshot.docs.length}');

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

      print('Found ${docs.length} notes with case-insensitive match');

      final notes = docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Note.fromMap(data);
      })
          .toList();

      // Sort by lastModified (newest first)
      notes.sort((a, b) => DateTime.parse(b.lastModified).compareTo(DateTime.parse(a.lastModified)));

      print('Processed ${notes.length} notes successfully');
      return notes;
    } catch (e) {
      print('Error getting notes: $e');
      throw Exception('Failed to load notes: $e');
    }
  }

  // Update an existing note
  Future<bool> updateNote(Map<String, dynamic> data, String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).update(data);
      return true;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();
      return true;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }
}