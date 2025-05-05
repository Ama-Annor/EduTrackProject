import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edu_track_project/controller/deadline_controller.dart';
import 'package:edu_track_project/model/deadline_model.dart';
import 'package:edu_track_project/screens/sub-pages/add_deadline.dart';
import 'package:edu_track_project/screens/widgets/calendar.dart';
import 'package:edu_track_project/screens/widgets/deadline_display.dart';

class DeadlinePage extends StatefulWidget {
  final String email;

  const DeadlinePage({super.key, required this.email});

  @override
  State<DeadlinePage> createState() => _DeadlinePageState();
}

class _DeadlinePageState extends State<DeadlinePage> {
  final DeadlineController _deadlineController = DeadlineController();
  List<Deadline> _deadlines = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Deadline> _filteredDeadlines = [];
  String _currentFilter = 'Selected Day'; // Default filter

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching deadlines for email: ${widget.email}');
      final deadlines = await _deadlineController.getAllDeadlines(widget.email);
      print('Fetched ${deadlines.length} deadlines');

      setState(() {
        _deadlines = deadlines;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchData: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load deadlines: $e'),
          backgroundColor: const Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case 'All':
      // Show all deadlines
        _filteredDeadlines = List.from(_deadlines);
        // Sort by date (earliest first)
        _filteredDeadlines.sort((a, b) =>
            DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate))
        );
        break;
      case 'Today':
      // Filter for today's deadlines
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        final String today = formatter.format(DateTime.now());
        _filteredDeadlines = _deadlines.where((deadline) => deadline.dueDate == today).toList();
        break;
      case 'This Week':
      // Filter for this week's deadlines
        final DateTime now = DateTime.now();
        final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
        final DateTime weekEnd = weekStart.add(const Duration(days: 6));
        _filteredDeadlines = _deadlines.where((deadline) {
          final DateTime deadlineDate = DateTime.parse(deadline.dueDate);
          return deadlineDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              deadlineDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
        // Sort by date (earliest first)
        _filteredDeadlines.sort((a, b) =>
            DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate))
        );
        break;
      case 'Selected Day':
      default:
      // Filter for the selected day from the calendar
        _filteredDeadlines = _filterDeadlinesByDate(_selectedDate);
        break;
    }
  }

  List<Deadline> _filterDeadlinesByDate(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formattedDate = formatter.format(date);
    print('Filtering deadlines for date: $formattedDate');

    final List<Deadline> filteredList = _deadlines.where((deadline) {
      final String deadlineDate = deadline.dueDate;
      final bool matches = deadlineDate == formattedDate;
      return matches;
    }).toList();

    print('Filtered ${filteredList.length} deadlines for date $formattedDate');
    return filteredList;
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _currentFilter = 'Selected Day'; // Reset to calendar selection
      _applyFilter();
    });
  }

  String _getFormattedDate() {
    final DateFormat formatter = DateFormat('MMMM d, yyyy');
    return formatter.format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        elevation: 0,
        title: const Text(
          'Deadlines',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 26,
            ),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
                context: context,
                builder: (context) => AddDeadline(
                  rootContext: context,
                  onDeadlineCreated: _fetchData,
                ),
              ).then((_) {
                // Make sure to refresh when modal is closed
                print('Add deadline modal closed, refreshing data...');
                _fetchData();
              });
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)))
          : RefreshIndicator(
        onRefresh: _fetchData,
        color: const Color(0xFF00BFA5),
        child: Column(
          children: [
            // Calendar section
            CustomCalendar(
              onDateSelected: _onDateSelected,
            ),

            // Filter options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentFilter == 'Selected Day')
                        Text(
                          _getFormattedDate(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          _currentFilter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      DropdownButton<String>(
                        dropdownColor: const Color.fromRGBO(38, 38, 38, 1),
                        value: _currentFilter,
                        icon: const Icon(Icons.filter_list, color: Color(0xFF00BFA5)),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _currentFilter = newValue;
                              _applyFilter();
                            });
                          }
                        },
                        style: const TextStyle(color: Colors.white),
                        underline: Container(
                          height: 2,
                          color: const Color(0xFF00BFA5),
                        ),
                        items: <String>['Selected Day', 'All', 'Today', 'This Week']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 1,
                    color: const Color.fromRGBO(63, 63, 63, 1),
                  ),
                ],
              ),
            ),

            // Deadlines list
            Expanded(
              child: _filteredDeadlines.isEmpty
                  ? Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.list,
                        size: 80,
                        color: Color(0xFF00BFA5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _currentFilter == 'Selected Day'
                            ? 'No deadlines for ${_getFormattedDate()}'
                            : 'No deadlines found',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap + to add a deadline',
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
                  : ListView.builder(
                // Add padding at the bottom to prevent content from being hidden by navigation bar
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: _filteredDeadlines.length,
                itemBuilder: (context, index) {
                  final deadline = _filteredDeadlines[index];

                  // For 'All' view, add date headers
                  if (_currentFilter == 'All' || _currentFilter == 'This Week') {
                    // Add date headers for better organization
                    bool showHeader = false;
                    if (index == 0) {
                      showHeader = true;
                    } else {
                      // Check if this date is different from previous one
                      final DateTime thisDate = DateTime.parse(deadline.dueDate);
                      final DateTime prevDate = DateTime.parse(_filteredDeadlines[index - 1].dueDate);
                      if (thisDate.day != prevDate.day ||
                          thisDate.month != prevDate.month ||
                          thisDate.year != prevDate.year) {
                        showHeader = true;
                      }
                    }

                    if (showHeader) {
                      final DateTime deadlineDate = DateTime.parse(deadline.dueDate);
                      final DateTime now = DateTime.now();
                      String headerText;

                      // Determine header text
                      if (deadlineDate.year == now.year &&
                          deadlineDate.month == now.month &&
                          deadlineDate.day == now.day) {
                        headerText = 'Today';
                      } else if (deadlineDate.year == now.year &&
                          deadlineDate.month == now.month &&
                          deadlineDate.day == now.day + 1) {
                        headerText = 'Tomorrow';
                      } else {
                        final DateFormat headerFormat = DateFormat('EEEE, MMMM d');
                        headerText = headerFormat.format(deadlineDate);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              headerText,
                              style: const TextStyle(
                                color: Color(0xFF00BFA5),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DeadlineTile(
                              date: deadline.dueDate,
                              time: deadline.reminderTime,
                              description: deadline.title,
                              deadline: deadline,
                              onDeadlineChanged: _fetchData,
                            ),
                          ),
                        ],
                      );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DeadlineTile(
                      date: deadline.dueDate,
                      time: deadline.reminderTime,
                      description: deadline.title,
                      deadline: deadline,
                      onDeadlineChanged: _fetchData,
                    ),
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