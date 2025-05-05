import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/controller/schedule_controller.dart';
import 'package:edu_track_project/model/schedule_model.dart';
import 'package:edu_track_project/screens/sub-pages/edit_schedule.dart';

class TaskDetailModal extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onScheduleChanged;

  const TaskDetailModal({
    super.key,
    required this.task,
    required this.onScheduleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime scheduleDate = DateTime.parse(task['date']);
    final DateFormat formatter = DateFormat('d MMMM, yyyy');
    final String formattedDate = formatter.format(scheduleDate);

    // Determine priority color
    Color priorityColor;
    switch (task['priority']) {
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task['course'],
            style: const TextStyle(
              color: Color(0xFF00BFA5),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task['subject'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task['priority'],
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  // Navigate to the EditSchedule screen with the current schedule data
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSchedule(
                        schedule: Schedule.fromMap(task),
                        rootContext: context,
                      ),
                    ),
                  );
                  // Refresh the schedules after editing
                  if (result == true) {
                    onScheduleChanged();
                  }
                  Navigator.pop(context); // Close the modal
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () async {
                  // Show a confirmation dialog before deleting
                  final bool? shouldDelete = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
                        title: const Text(
                          'Confirm Delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        content: const Text(
                          'Are you sure you want to delete this schedule?',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF00BFA5)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Color(0xFF00BFA5)),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldDelete == true) {
                    try {
                      // Call the delete function from your controller
                      await ScheduleController().deleteSchedule(task['schedule_id']);
                      Navigator.pop(context); // Close the modal
                      onScheduleChanged(); // Refresh the list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Schedule deleted successfully',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Color(0xFF00BFA5),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete schedule: $e',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF00BFA5),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formattedDate,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'From',
                style: TextStyle(color: Color(0xFF00BFA5)),
              ),
              const SizedBox(width: 8),
              Text(
                task['start'],
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'To',
                style: TextStyle(color: Color(0xFF00BFA5)),
              ),
              const SizedBox(width: 8),
              Text(
                task['end'],
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Description:',
            style: TextStyle(
              color: Color(0xFF00BFA5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task['description'],
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}