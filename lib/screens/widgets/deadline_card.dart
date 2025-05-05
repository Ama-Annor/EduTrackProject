import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/model/deadline_model.dart';

class DeadlineCard extends StatelessWidget {
  final Deadline deadline;

  const DeadlineCard({super.key, required this.deadline});

  @override
  Widget build(BuildContext context) {
    final DateTime dueDate = DateTime.parse(deadline.dueDate);
    final DateFormat formatter = DateFormat('d MMMM, yyyy');
    final String formattedDate = formatter.format(dueDate);

    // Calculate days remaining more accurately
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    // Calculate the difference in days
    final int daysRemaining = dueDateDay.difference(today).inDays;

    // Determine status text and color
    String statusText;
    Color statusColor;

    if (daysRemaining < 0) {
      statusText = 'Overdue';
      statusColor = Colors.red;
    } else if (daysRemaining == 0) {
      statusText = 'Today';
      statusColor = const Color.fromRGBO(255, 130, 0, 1); // Orange
    } else if (daysRemaining == 1) {
      statusText = 'Tomorrow';
      statusColor = const Color.fromRGBO(255, 160, 0, 1); // Light orange
    } else {
      statusText = '$daysRemaining days left';
      if (daysRemaining <= 3) {
        statusColor = const Color.fromRGBO(255, 190, 0, 1); // Amber
      } else {
        statusColor = const Color(0xFF00BFA5); // Teal (your app's primary color)
      }
    }

    // Determine border color based on urgency
    Color borderColor;
    if (daysRemaining < 0) {
      borderColor = Colors.red; // Overdue
    } else if (daysRemaining <= 2) {
      borderColor = const Color.fromRGBO(255, 63, 23, 0.8); // Urgent (0-2 days)
    } else if (daysRemaining <= 5) {
      borderColor = Colors.amber; // Soon (3-5 days)
    } else {
      borderColor = const Color(0xFF00BFA5); // Plenty of time (6+ days)
    }

    return Card(
      color: const Color.fromRGBO(38, 38, 38, 1),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deadline.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Due: $formattedDate',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Time: ${deadline.reminderTime}',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}