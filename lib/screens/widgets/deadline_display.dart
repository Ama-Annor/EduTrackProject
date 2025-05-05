import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/model/deadline_model.dart';
import 'package:edu_track_project/screens/widgets/deadline_modal.dart';

class DeadlineTile extends StatelessWidget {
  final String date;
  final String time;
  final String description;
  final Deadline deadline;
  final VoidCallback onDeadlineChanged;

  const DeadlineTile({
    super.key,
    required this.date,
    required this.time,
    required this.description,
    required this.deadline,
    required this.onDeadlineChanged,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime dueDate = DateTime.parse(date);
    final DateFormat formatter = DateFormat('d MMMM, yyyy');
    final String formattedDate = formatter.format(dueDate);

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
                  constraints: const BoxConstraints(maxWidth: 100.0),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Color(0xFF00BFA5),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white, size: 30),
                  onPressed: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
                      context: context,
                      builder: (context) => DeadlineModal(
                        task: deadline.toMap(),
                        onDeadlineChanged: onDeadlineChanged,
                      ),
                    );
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