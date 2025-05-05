import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/studyhour_controller.dart';
import 'package:edu_track_project/controller/studytimer_controller.dart';
import 'package:edu_track_project/model/studyhour_model.dart';
import 'package:edu_track_project/model/studytimer_model.dart';
import 'package:edu_track_project/screens/sub-pages/create_studyhour.dart';
//import 'package:edu_track_project/screens/widgets/studyhour_card.dart';
import 'package:intl/intl.dart';

class ViewStudyHourLogs extends StatefulWidget {
  final String? email;

  const ViewStudyHourLogs({super.key, this.email});

  @override
  State<ViewStudyHourLogs> createState() => _ViewStudyHourLogsState();
}

class _ViewStudyHourLogsState extends State<ViewStudyHourLogs> with SingleTickerProviderStateMixin {
  final StudyhourController _studyhourController = StudyhourController();
  final StudytimerController _studytimerController = StudytimerController();
  late Future<List<dynamic>> _studySessions;
  late String _userEmail;
  String _filterOption = 'All';
  final List<String> _filterOptions = ['All', 'Today', 'This Week', 'This Month'];
  List<dynamic> _allSessions = [];
  bool _isLoading = true;
  bool _showTimerSessions = true;
  bool _showManualSessions = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userEmail = widget.email ?? FirebaseAuth.instance.currentUser!.email!;
    _studySessions = _fetchData(_userEmail);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        if (_tabController.index == 0) {
          // All Sessions
          _showTimerSessions = true;
          _showManualSessions = true;
        } else {
          // Manual Sessions
          _showTimerSessions = false;
          _showManualSessions = true;
        }
      });
      _refreshStudySessions();
    }
  }

  Future<void> _refreshStudySessions() async {
    setState(() {
      _isLoading = true;
      _studySessions = _fetchData(_userEmail);
    });
  }

  void _deleteStudySession(dynamic studySession) async {
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
            'Are you sure you want to delete this study session?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF00BFA5)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
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
        if (studySession is StudyHour) {
          await _studyhourController.deleteStudyhour(studySession.studyhour_id);
        } else if (studySession is Studytimer) {
          await _studytimerController.deleteStudytimer(studySession.studytimer_id);
        }

        _refreshStudySessions();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Successfully deleted study session',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete session: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<List<dynamic>> _fetchData(String email) async {
    try {
      List<dynamic> allSessions = [];

      // Fetch manual study hours
      if (_showManualSessions) {
        final studyHours = await _studyhourController.getAllStudyhours(email);
        allSessions.addAll(studyHours);
      }

      // Fetch timer sessions
      if (_showTimerSessions) {
        final studyTimers = await _studytimerController.getAllStudytimers(email);
        allSessions.addAll(studyTimers);
      }

      // Apply filters
      final filteredSessions = _applyFilters(allSessions, _filterOption);

      // Store all sessions for reference
      _allSessions = filteredSessions;
      _isLoading = false;

      return filteredSessions;
    } catch (e) {
      print('Error fetching study sessions: $e');
      _isLoading = false;
      rethrow;
    }
  }

  List<dynamic> _applyFilters(List<dynamic> sessions, String filterOption) {
    if (filterOption == 'All') {
      return sessions;
    }

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return sessions.where((session) {
      DateTime sessionDate;

      if (session is StudyHour) {
        sessionDate = _parseDate(session.loggedDate);
      } else if (session is Studytimer) {
        sessionDate = _parseDate(session.date);
      } else {
        return false; // Unknown session type
      }

      if (filterOption == 'Today') {
        return sessionDate.year == today.year &&
            sessionDate.month == today.month &&
            sessionDate.day == today.day;
      } else if (filterOption == 'This Week') {
        // Find the start of the current week (Sunday)
        final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        return sessionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            sessionDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      } else if (filterOption == 'This Month') {
        return sessionDate.year == today.year && sessionDate.month == today.month;
      }

      return true; // Default to show all
    }).toList();
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        final DateFormat format = DateFormat('yyyy-MM-dd');
        return format.parse(dateString);
      } catch (e) {
        print('Error parsing date: $dateString');
        return DateTime.now(); // Fallback
      }
    }
  }

  void _changeFilter(String? newFilter) {
    if (newFilter != null && newFilter != _filterOption) {
      setState(() {
        _filterOption = newFilter;
        _isLoading = true;
      });
      _refreshStudySessions();
    }
  }

  String _getSessionDuration(dynamic session) {
    if (session is StudyHour) {
      return session.hoursLogged;
    } else if (session is Studytimer) {
      // Calculate duration from start and end time
      try {
        final DateFormat format = DateFormat('HH:mm');
        final start = format.parse(session.startTime);
        final end = format.parse(session.endTime);

        // If end is before start, assume it's the next day
        final duration = end.isBefore(start)
            ? end.add(const Duration(days: 1)).difference(start)
            : end.difference(start);

        final hours = duration.inHours;
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');

        return '${hours}h ${minutes}m';
      } catch (e) {
        print('Error calculating duration: $e');
        return '?h ?m';
      }
    }

    return '0h 0m';
  }

  String _getTotalHours() {
    int totalMinutes = 0;

    for (var session in _allSessions) {
      if (session is StudyHour) {
        final parts = session.hoursLogged.split('h ');
        if (parts.length == 2) {
          int hours = int.tryParse(parts[0]) ?? 0;
          int minutes = int.tryParse(parts[1].replaceAll('m', '')) ?? 0;
          totalMinutes += (hours * 60) + minutes;
        }
      } else if (session is Studytimer) {
        try {
          final DateFormat format = DateFormat('HH:mm');
          final start = format.parse(session.startTime);
          var end = format.parse(session.endTime);

          // If end is before start, assume it's the next day
          if (end.isBefore(start)) {
            end = end.add(const Duration(days: 1));
          }

          final duration = end.difference(start);
          totalMinutes += duration.inMinutes;
        } catch (e) {
          print('Error calculating timer duration: $e');
        }
      }
    }

    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _getSessionDate(dynamic session) {
    String dateString = '';

    if (session is StudyHour) {
      dateString = session.loggedDate;
    } else if (session is Studytimer) {
      dateString = session.date;
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getDurationColor(String duration) {
    // Get just the hour value
    final hourValue = double.tryParse(
        duration.split('h')[0].trim()
    ) ?? 0.0;

    if (hourValue >= 3) {
      return const Color.fromARGB(255, 0, 145, 125); // Deep teal for 3+ hours
    } else if (hourValue >= 2) {
      return const Color.fromARGB(255, 38, 166, 154); // Medium teal for 2+ hours
    } else if (hourValue >= 1) {
      return const Color.fromARGB(255, 77, 182, 172); // Light teal for 1+ hour
    } else {
      return const Color.fromARGB(255, 128, 203, 196); // Very light teal for < 1 hour
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        title: const Text('Study Logs',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 26),
            onPressed: _refreshStudySessions,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
                context: context,
                builder: (context) => CreateStudyhour(
                  rootContext: context,
                  onStudyHourCreated: _refreshStudySessions,
                ),
              ).whenComplete(() {
                _refreshStudySessions();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00BFA5),
          labelColor: const Color(0xFF00BFA5),
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'All Sessions'),
            Tab(text: 'Manual Logs'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0), // Added bottom padding
        child: Column(
          children: [
            // Filter dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(38, 38, 38, 1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterOption,
                  isExpanded: true,
                  dropdownColor: const Color.fromRGBO(38, 38, 38, 1),
                  style: const TextStyle(color: Colors.white),
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  items: _filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: _changeFilter,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Study sessions list
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _studySessions,
                builder: (context, snapshot) {
                  if (_isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF00BFA5),
                            size: 72,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No study logs for $_filterOption',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to add your study hours\nor use the timer to track study sessions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final studySessions = snapshot.data!;

                  // Group study sessions by date
                  Map<String, List<dynamic>> sessionsByDate = {};
                  for (var session in studySessions) {
                    String dateString = '';
                    if (session is StudyHour) {
                      dateString = session.loggedDate;
                    } else if (session is Studytimer) {
                      dateString = session.date;
                    }

                    if (!sessionsByDate.containsKey(dateString)) {
                      sessionsByDate[dateString] = [];
                    }
                    sessionsByDate[dateString]?.add(session);
                  }

                  // Sort dates (most recent first)
                  List<String> sortedDates = sessionsByDate.keys.toList();
                  sortedDates.sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

                  // Show total hours
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(38, 38, 38, 1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00BFA5).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Study Time:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BFA5).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF00BFA5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getTotalHours(),
                                style: const TextStyle(
                                  color: Color(0xFF00BFA5),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshStudySessions,
                          color: const Color(0xFF00BFA5),
                          child: ListView.builder(
                            itemCount: sortedDates.length,
                            padding: const EdgeInsets.only(bottom: 90), // Extra padding at bottom
                            itemBuilder: (context, dateIndex) {
                              final dateString = sortedDates[dateIndex];
                              final sessions = sessionsByDate[dateString] ?? [];

                              // Format the date for display
                              String formattedDate = '';
                              try {
                                final date = DateTime.parse(dateString);
                                final now = DateTime.now();
                                final today = DateTime(now.year, now.month, now.day);
                                final yesterday = today.subtract(const Duration(days: 1));

                                if (date.year == today.year && date.month == today.month && date.day == today.day) {
                                  formattedDate = 'Today';
                                } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
                                  formattedDate = 'Yesterday';
                                } else {
                                  formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);
                                }
                              } catch (e) {
                                formattedDate = dateString;
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ...sessions.map((session) {
                                    // Determine if this is a timer session or manual entry
                                    final isTimer = session is Studytimer;

                                    // Get the duration
                                    final duration = _getSessionDuration(session);

                                    // Get the course name
                                    final course = isTimer
                                        ? (session as Studytimer).course
                                        : (session as StudyHour).course;

                                    // Get session time info
                                    String timeInfo = '';
                                    if (isTimer) {
                                      final timer = session as Studytimer;
                                      timeInfo = '${timer.startTime} - ${timer.endTime}';
                                    }

                                    return Card(
                                      color: const Color.fromRGBO(38, 38, 38, 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15.0),
                                      ),
                                      elevation: 4,
                                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        title: Row(
                                          children: [
                                            // Session type icon
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isTimer
                                                    ? const Color.fromRGBO(255, 63, 23, 0.2)
                                                    : const Color(0xFF00BFA5).withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isTimer ? Icons.timer : Icons.edit_note,
                                                color: isTimer
                                                    ? const Color.fromRGBO(255, 63, 23, 1)
                                                    : const Color(0xFF00BFA5),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    course,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  if (timeInfo.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      timeInfo,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getDurationColor(duration).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _getDurationColor(duration),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                duration,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: _getDurationColor(duration),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.white70,
                                          ),
                                          onPressed: () => _deleteStudySession(session),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}