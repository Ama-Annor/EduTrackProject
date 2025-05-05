import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/model/schedule_model.dart';
import 'package:edu_track_project/screens/widgets/task_detail_modal.dart';

class SchedulesCard extends StatelessWidget {
  final String date;
  final String time;
  final String course;
  final String subject;
  final Schedule schedule;
  final VoidCallback onScheduleChanged;

  const SchedulesCard({
    super.key,
    required this.date,
    required this.time,
    required this.course,
    required this.subject,
    required this.schedule,
    required this.onScheduleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime scheduleDate = DateTime.parse(date);
    final DateFormat formatter = DateFormat('d MMMM, yyyy');
    final String formattedDate = formatter.format(scheduleDate);

    // Determine priority color
    Color priorityColor;
    switch (schedule.priority) {
      case 'High':
        priorityColor = Colors.redAccent;
        break;
      case 'Medium':
        priorityColor = Colors.orangeAccent;
        break;
      case 'Low':
        priorityColor = Colors.greenAccent;
        break;
      default:
        priorityColor = const Color(0xFF00BFA5);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(38, 38, 38, 1),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Divider(
            color: Color.fromRGBO(63, 63, 63, 1),
            thickness: 2.0,
            height: 2.0,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80.0),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Color(0xFF00BFA5),
                      fontSize: 16.0,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Priority indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          schedule.priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Time: $time',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        course,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subject,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white, size: 30),
                  onPressed: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
                      context: context,
                      builder: (context) => TaskDetailModal(
                        task: schedule.toMap(),
                        onScheduleChanged: onScheduleChanged,
                      ),
                    ).then((_) {
                      // Refresh when modal is closed
                      onScheduleChanged();
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(
            color: Color.fromRGBO(63, 63, 63, 1),
            thickness: 2.0,
            height: 2.0,
          ),
        ],
      ),
    );
  }
}