import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/model/deadline_model.dart';

// DeadlineCard is used in horizontal lists like on Dashboard
class DeadlineCard extends StatelessWidget {
  final Deadline deadline;

  const DeadlineCard({super.key, required this.deadline});

  @override
  Widget build(BuildContext context) {
    final DateTime dueDate = DateTime.parse(deadline.dueDate);
    final DateFormat formatter = DateFormat('d MMMM, yyyy');
    final String formattedDate = formatter.format(dueDate);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.transparent,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(255, 63, 23, 0.6), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 18),
                Text(
                  'Due: $formattedDate',
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// DeadlineTile is used in vertical lists on the Deadlines page
class DeadlineTile extends StatelessWidget {
  final String date;
  final String time;
  final String description;
  final Deadline deadline;

  const DeadlineTile({
    Key? key,
    required this.date,
    required this.time,
    required this.description,
    required this.deadline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse the date string to a DateTime object
    DateTime dueDate;
    try {
      dueDate = DateTime.parse(date);
    } catch (e) {
      // Fallback if date can't be parsed
      dueDate = DateTime.now();
    }

    final DateFormat formatter = DateFormat('d MMMM, yyyy');
    final String formattedDate = formatter.format(dueDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
            if (deadline.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                deadline.description,
                style: const TextStyle(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: deadline.setReminder == 'true' || deadline.setReminder == 'Yes'
            ? const Icon(Icons.alarm, color: Color(0xFF00BFA5))
            : null,
      ),
    );
  }
}