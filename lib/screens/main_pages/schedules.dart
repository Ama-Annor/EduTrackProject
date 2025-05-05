import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/controller/schedule_controller.dart';
import 'package:edu_track_project/model/schedule_model.dart';
import 'package:edu_track_project/screens/sub-pages/create_schedule.dart';
import 'package:edu_track_project/screens/widgets/calendar.dart';
import 'package:edu_track_project/screens/widgets/schedule_card.dart';

class SchedulesPage extends StatefulWidget {
  final String email;

  const SchedulesPage({super.key, required this.email});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  final ScheduleController _scheduleController = ScheduleController();
  List<Schedule> _schedules = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Schedule> _filteredSchedules = [];
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
      print('Fetching schedules for email: ${widget.email}');
      final schedules = await _scheduleController.getAllSchedules(widget.email);
      print('Fetched ${schedules.length} schedules');

      setState(() {
        _schedules = schedules;
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
          content: Text('Failed to load schedules: $e'),
          backgroundColor: const Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case 'All':
      // Show all schedules
        _filteredSchedules = List.from(_schedules);
        // Sort by date and time
        _filteredSchedules.sort((a, b) {
          int dateComparison = DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
          if (dateComparison != 0) return dateComparison;

          // If same date, compare by start time
          return a.start.compareTo(b.start);
        });
        break;
      case 'Today':
      // Filter for today's schedules
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        final String today = formatter.format(DateTime.now());
        _filteredSchedules = _schedules.where((schedule) => schedule.date == today).toList();
        // Sort by start time
        _filteredSchedules.sort((a, b) => a.start.compareTo(b.start));
        break;
      case 'This Week':
      // Filter for this week's schedules
        final DateTime now = DateTime.now();
        final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
        final DateTime weekEnd = weekStart.add(const Duration(days: 6));
        _filteredSchedules = _schedules.where((schedule) {
          final DateTime scheduleDate = DateTime.parse(schedule.date);
          return scheduleDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              scheduleDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
        // Sort by date and then time
        _filteredSchedules.sort((a, b) {
          int dateComparison = DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
          if (dateComparison != 0) return dateComparison;
          return a.start.compareTo(b.start);
        });
        break;
      case 'Selected Day':
      default:
      // Filter for the selected day from the calendar
        _filteredSchedules = _filterSchedulesByDate(_selectedDate);
        // Sort by start time
        _filteredSchedules.sort((a, b) => a.start.compareTo(b.start));
        break;
    }
  }

  List<Schedule> _filterSchedulesByDate(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formattedDate = formatter.format(date);
    print('Filtering schedules for date: $formattedDate');

    final List<Schedule> filteredList = _schedules.where((schedule) {
      final String scheduleDate = schedule.date;
      final bool matches = scheduleDate == formattedDate;
      return matches;
    }).toList();

    print('Filtered ${filteredList.length} schedules for date $formattedDate');
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

  void _navigateToAddSchedulePage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSchedule(
          email: widget.email,
          rootContext: context,
        ),
      ),
    );

    if (result == true) {
      _fetchData(); // Refresh the schedules list if there's an update
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        elevation: 0,
        title: const Text(
          'Schedules',
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
            onPressed: () => _navigateToAddSchedulePage(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
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

            // Schedules list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)))
                  : _filteredSchedules.isEmpty
                  ? Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_note,
                        size: 80,
                        color: Color(0xFF00BFA5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _currentFilter == 'Selected Day'
                            ? 'No schedules for ${_getFormattedDate()}'
                            : 'No schedules found',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap + to add a schedule',
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
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: _filteredSchedules.length,
                itemBuilder: (context, index) {
                  final schedule = _filteredSchedules[index];

                  // For 'All' view and 'This Week', add date headers
                  if (_currentFilter == 'All' || _currentFilter == 'This Week') {
                    // Add date headers for better organization
                    bool showHeader = false;
                    if (index == 0) {
                      showHeader = true;
                    } else {
                      // Check if this date is different from previous one
                      final DateTime thisDate = DateTime.parse(schedule.date);
                      final DateTime prevDate = DateTime.parse(_filteredSchedules[index - 1].date);
                      if (thisDate.day != prevDate.day ||
                          thisDate.month != prevDate.month ||
                          thisDate.year != prevDate.year) {
                        showHeader = true;
                      }
                    }

                    if (showHeader) {
                      final DateTime scheduleDate = DateTime.parse(schedule.date);
                      final DateTime now = DateTime.now();
                      String headerText;

                      // Determine header text
                      if (scheduleDate.year == now.year &&
                          scheduleDate.month == now.month &&
                          scheduleDate.day == now.day) {
                        headerText = 'Today';
                      } else if (scheduleDate.year == now.year &&
                          scheduleDate.month == now.month &&
                          scheduleDate.day == now.day + 1) {
                        headerText = 'Tomorrow';
                      } else {
                        final DateFormat headerFormat = DateFormat('EEEE, MMMM d');
                        headerText = headerFormat.format(scheduleDate);
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
                          SchedulesCard(
                            course: schedule.course,
                            subject: schedule.subject,
                            date: schedule.date,
                            time: schedule.start,
                            schedule: schedule,
                            onScheduleChanged: _fetchData,
                          ),
                        ],
                      );
                    }
                  }

                  return SchedulesCard(
                    course: schedule.course,
                    subject: schedule.subject,
                    date: schedule.date,
                    time: schedule.start,
                    schedule: schedule,
                    onScheduleChanged: _fetchData,
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