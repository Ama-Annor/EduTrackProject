import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/controller/deadline_controller.dart';
import 'package:edu_track_project/model/deadline_model.dart';
import 'package:edu_track_project/screens/sub-pages/edit_deadline.dart';

class DeadlineModal extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onDeadlineChanged;

  const DeadlineModal({
    super.key,
    required this.task,
    required this.onDeadlineChanged,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime dueDate = DateTime.parse(task['dueDate']);
    final DateFormat formatter = DateFormat('d MMMM, yyyy');
    final String formattedDate = formatter.format(dueDate);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task['title'],
            style: const TextStyle(
              color: Color(0xFF00BFA5),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                task['reminderTime'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  // Navigate to the EditDeadline screen with the current deadline data
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDeadline(
                        deadline: Deadline.fromMap(task),
                        rootContext: context,
                      ),
                    ),
                  );
                  // Refresh the deadlines after editing
                  onDeadlineChanged();
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
                          'Are you sure you want to delete this deadline?',
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
                      await DeadlineController().deleteDeadline(task['deadline_id']);
                      Navigator.pop(context); // Close the modal
                      onDeadlineChanged(); // Refresh the list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Deadline deleted successfully',
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
                            'Failed to delete deadline: $e',
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

          const SizedBox(height: 20),
          const Text(
            'Description:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task['description'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}