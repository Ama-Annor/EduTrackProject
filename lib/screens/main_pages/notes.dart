import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/controller/note_controller.dart';
import 'package:edu_track_project/model/note_model.dart';
import 'package:edu_track_project/screens/sub-pages/add_notes.dart';
import 'package:edu_track_project/screens/widgets/notes_card.dart';

class NotesPage extends StatefulWidget {
  final String email;
  const NotesPage({super.key, required this.email});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteController _noteController = NoteController();
  late List<Note> _allNotes = [];
  late List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'All'; // Default filter

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching notes for email: ${widget.email}');
      final notes = await _noteController.getAllNotes(widget.email);
      print('Fetched ${notes.length} notes');

      setState(() {
        _allNotes = notes;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchData: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load notes: $e'),
          backgroundColor: const Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyFilters() {
    // Start with all notes
    List<Note> result = List.from(_allNotes);

    // Apply date filter
    switch (_currentFilter) {
      case 'Today':
        final DateTime now = DateTime.now();
        final String today = DateFormat('yyyy-MM-dd').format(now);
        result = result.where((note) {
          final DateTime noteDate = DateTime.parse(note.lastModified);
          final String noteDay = DateFormat('yyyy-MM-dd').format(noteDate);
          return noteDay == today;
        }).toList();
        break;

      case 'This Week':
        final DateTime now = DateTime.now();
        final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
        final DateTime weekEnd = weekStart.add(const Duration(days: 6));

        result = result.where((note) {
          final DateTime noteDate = DateTime.parse(note.lastModified);
          return noteDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              noteDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
        break;

      case 'This Month':
        final DateTime now = DateTime.now();
        final DateTime monthStart = DateTime(now.year, now.month, 1);
        final DateTime monthEnd = (now.month < 12)
            ? DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1))
            : DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1));

        result = result.where((note) {
          final DateTime noteDate = DateTime.parse(note.lastModified);
          return noteDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
              noteDate.isBefore(monthEnd.add(const Duration(days: 1)));
        }).toList();
        break;

      case 'All':
      default:
      // No additional filtering needed
        break;
    }

    // Apply search filter if present
    if (_searchQuery.isNotEmpty) {
      result = result.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredNotes = result;
    });
  }

  Future<void> _refreshNotes() async {
    _searchController.clear();
    _searchQuery = '';
    await _fetchData();
  }

  void _deleteNote(Note note) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
          title: const Text(
            'Confirm Deletion',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this note?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User pressed "Cancel"
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF00BFA5)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // User pressed "Delete"
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFF00BFA5)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _noteController.deleteNote(note.note_id);
        await _fetchData(); // Refresh notes after deletion

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Successfully deleted note',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getFilterDescription() {
    switch (_currentFilter) {
      case 'Today':
        return 'Notes modified today';
      case 'This Week':
        return 'Notes modified this week';
      case 'This Month':
        return 'Notes modified this month';
      case 'All':
      default:
        return 'All notes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        title: const Text(
          'Notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 26,
            ),
            onPressed: _refreshNotes,
          ),
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewNotePage(email: widget.email),
                ),
              );

              if (result != null) {
                await _fetchData(); // Refresh notes after adding
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Search bar and filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: const Color.fromRGBO(38, 38, 38, 1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),

                // Filter dropdown and description
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Filter description
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          _getFilterDescription(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    // Filter dropdown
                    DropdownButton<String>(
                      dropdownColor: const Color.fromRGBO(38, 38, 38, 1),
                      value: _currentFilter,
                      icon: const Icon(Icons.filter_list, color: Color(0xFF00BFA5)),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _currentFilter = newValue;
                            _applyFilters();
                          });
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      underline: Container(
                        height: 2,
                        color: const Color(0xFF00BFA5),
                      ),
                      items: <String>['All', 'Today', 'This Week', 'This Month']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color.fromRGBO(63, 63, 63, 1), height: 1),

          // Notes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)))
                : _filteredNotes.isEmpty
                ? Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.note,
                      size: 80,
                      color: Color(0xFF00BFA5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No notes match your search'
                          : _currentFilter == 'All'
                          ? 'No notes yet'
                          : 'No notes for this time period',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tap + to add a note',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _refreshNotes,
              color: const Color(0xFF00BFA5),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 90), // Add padding for bottom nav bar
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) {
                  return NotesCard(
                    note: _filteredNotes[index],
                    onDelete: () => _deleteNote(_filteredNotes[index]),
                    rootContext: context,
                    onNoteChanged: _fetchData,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewNotePage(email: widget.email),
            ),
          );

          if (result != null) {
            await _fetchData();
          }
        },
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add),
      ),
    );
  }
}