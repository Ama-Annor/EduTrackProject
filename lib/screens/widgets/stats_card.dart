import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/studyhour_controller.dart';
import 'package:edu_track_project/controller/studytimer_controller.dart';
import 'package:edu_track_project/model/studyhour_model.dart';
import 'package:edu_track_project/model/studytimer_model.dart';
import 'package:intl/intl.dart';

class StatsCard extends StatefulWidget {
  final String value;
  final String email;

  const StatsCard({
    super.key,
    required this.value,
    required this.email,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  final StudyhourController _studyhourController = StudyhourController();
  final StudytimerController _studytimerController = StudytimerController();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, double> _courseTotals = {};
  double _totalHours = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(StatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.email != widget.email) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<StudyHour> studyHours = [];
      List<Studytimer> studyTimers = [];

      // Fetch data from both sources
      try {
        final studyHourResponse = await _studyhourController.getAllStudyhours(widget.email);
        studyHours.addAll(studyHourResponse);
        print('Fetched ${studyHours.length} study hours');
      } catch (e) {
        print('Error fetching study hours: $e');
      }

      try {
        final studyTimerResponse = await _studytimerController.getAllStudytimers(widget.email);
        studyTimers.addAll(studyTimerResponse);
        print('Fetched ${studyTimers.length} study timers');
      } catch (e) {
        print('Error fetching study timers: $e');
      }

      // Filter data based on the value (today or week)
      if (widget.value == 'today') {
        studyHours = studyHours
            .where((hour) => isToday(parseDate(hour.loggedDate)))
            .toList();

        studyTimers = studyTimers
            .where((timer) => isToday(parseDate(timer.date)))
            .toList();

        print('Filtered to ${studyHours.length} study hours and ${studyTimers.length} study timers for today');
      } else if (widget.value == 'week') {
        DateTime now = DateTime.now();
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

        studyHours = studyHours
            .where((hour) => isInWeek(parseDate(hour.loggedDate), startOfWeek, endOfWeek))
            .toList();

        studyTimers = studyTimers
            .where((timer) => isInWeek(parseDate(timer.date), startOfWeek, endOfWeek))
            .toList();

        print('Filtered to ${studyHours.length} study hours and ${studyTimers.length} study timers for this week');
      }

      final courseTotals = calculateCourseTotals(studyHours, studyTimers);

      setState(() {
        _courseTotals = courseTotals;
        _totalHours = courseTotals.values.fold(0.0, (a, b) => a + b);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
      print('Error in fetchData: $e');
    }
  }

  bool isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool isInWeek(DateTime date, DateTime startOfWeek, DateTime endOfWeek) {
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  DateTime parseDate(String dateString) {
    // Handle various date formats
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try alternative format
      try {
        final DateFormat format = DateFormat('yyyy-MM-dd');
        return format.parse(dateString);
      } catch (e) {
        print('Failed to parse date: $dateString. Using current date.');
        return DateTime.now();
      }
    }
  }

  Map<String, double> calculateCourseTotals(
      List<StudyHour> studyHours, List<Studytimer> studyTimers) {
    Map<String, double> totals = {};

    // Process timers
    for (var timer in studyTimers) {
      String course = timer.course.toLowerCase();
      double duration = calculateDuration(timer.startTime, timer.endTime);

      if (duration > 0) {
        if (totals.containsKey(course)) {
          totals[course] = totals[course]! + duration;
        } else {
          totals[course] = duration;
        }
      }
    }

    // Process manually logged hours
    for (var hour in studyHours) {
      String course = hour.course.toLowerCase();
      try {
        double hours = parseHoursLogged(hour.hoursLogged);

        if (hours > 0) {
          if (totals.containsKey(course)) {
            totals[course] = totals[course]! + hours;
          } else {
            totals[course] = hours;
          }
        }
      } catch (e) {
        print('Error parsing hours logged for $course: ${hour.hoursLogged}');
      }
    }

    return totals;
  }

  double calculateDuration(String startTime, String endTime) {
    try {
      DateFormat dateFormat = DateFormat('HH:mm'); // 24-hour format
      DateTime start = dateFormat.parse(startTime.trim());
      DateTime end = dateFormat.parse(endTime.trim());

      // If end time is before start time, assume it's the next day
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }

      Duration duration = end.difference(start);
      return duration.inMinutes / 60.0;
    } catch (e) {
      print('Failed to parse time: $startTime - $endTime. Error: $e');
      return 0.0;
    }
  }

  double parseHoursLogged(String hoursLogged) {
    // Handle various formats like "2h 30m" or "2.5h"
    try {
      if (hoursLogged.contains('h') && hoursLogged.contains('m')) {
        final parts = hoursLogged.split('h ');
        if (parts.length == 2) {
          int hours = int.parse(parts[0].trim());
          int minutes = int.parse(parts[1].replaceAll('m', '').trim());
          return hours + minutes / 60.0;
        }
      } else if (hoursLogged.contains('h')) {
        return double.parse(hoursLogged.replaceAll('h', '').trim());
      } else if (hoursLogged.contains('.')) {
        return double.parse(hoursLogged);
      }

      // Default fallback
      return double.parse(hoursLogged);
    } catch (e) {
      print('Failed to parse hours logged: $hoursLogged. Error: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromRGBO(29, 29, 29, 0.2),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Reduced vertical padding
        constraints: const BoxConstraints(minHeight: 180), // Adjusted minimum height
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                    'Study Time',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                    )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00BFA5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_totalHours.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF00BFA5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              widget.value == 'today' ? 'Today\'s Progress' : 'This Week\'s Progress',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5))))
                : _errorMessage.isNotEmpty
                ? Expanded(child: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white))))
                : _courseTotals.isEmpty
                ? Expanded(child: _buildEmptyState())
                : Expanded(child: _buildBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      // Set a specific height that will comfortably fit the content
      height: 120, // This should be enough for the icon and text
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent expansion
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 36, // Further reduced size
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8), // Smaller spacing
          Text(
            widget.value == 'today'
                ? 'No study sessions today'
                : 'No study sessions this week',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13, // Even smaller text
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Sort courses by study time (descending)
    var sortedEntries = _courseTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get maximum value for scaling
    double maxValue = sortedEntries.isEmpty ? 1.0 : sortedEntries.first.value;

    // Limit to top 6 courses to avoid overflow
    var displayEntries = sortedEntries.take(6).toList();

    // Generate consistent colors
    final colorList = [
      const Color(0xFF00BFA5), // Teal (primary app color)
      const Color(0xFFE57373), // Light Red
      const Color(0xFF64B5F6), // Light Blue
      const Color(0xFFFFB74D), // Orange
      const Color(0xFF81C784), // Light Green
      const Color(0xFFBA68C8), // Light Purple
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        children: [
          // Bar chart section
          Expanded(
            child: ListView.builder(
              itemCount: displayEntries.length,
              itemBuilder: (context, index) {
                final entry = displayEntries[index];
                final percentage = (entry.value / _totalHours) * 100;
                final barWidth = (entry.value / maxValue) * 0.75; // Scale to 75% of width

                // Format the course name (capitalize first letter)
                final courseName = entry.key.isNotEmpty
                    ? '${entry.key[0].toUpperCase()}${entry.key.substring(1)}'
                    : 'Unknown';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              courseName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${entry.value.toStringAsFixed(2)}h',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Bar
                      Stack(
                        children: [
                          // Background bar
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Value bar
                          FractionallySizedBox(
                            widthFactor: barWidth >= 0.02 ? barWidth : 0.02, // Minimum visible width
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: colorList[index % colorList.length],
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorList[index % colorList.length].withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Percentage
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // "And X more" text if there are more courses
          if (sortedEntries.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'and ${sortedEntries.length - 6} more...',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic
                ),
              ),
            ),
        ],
      ),
    );
  }
}