import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/model/studyhour_model.dart';
import 'package:edu_track_project/screens/sub-pages/edit_studyhour.dart';

class StudyHourCard extends StatelessWidget {
  final StudyHour studyHour;
  final VoidCallback onDelete;
  final BuildContext rootContext;

  const StudyHourCard({
    super.key,
    required this.studyHour,
    required this.onDelete,
    required this.rootContext,
  });

  @override
  Widget build(BuildContext context) {
    final name = studyHour.course;
    final hrsLogged = studyHour.hoursLogged;
    final dateLogged = studyHour.loggedDate;

    final DateTime dueDate = DateTime.parse(dateLogged);
    final DateFormat formatter = DateFormat('d MMMM, yyyy');
    final String formattedDate = formatter.format(dueDate);

    // Get just the hour value for color coding
    final hourValue = double.tryParse(
        hrsLogged.split('h')[0].trim()
    ) ?? 0.0;

    Color cardColor;
    if (hourValue >= 3) {
      cardColor = const Color.fromARGB(255, 0, 145, 125); // Deep teal for 3+ hours
    } else if (hourValue >= 2) {
      cardColor = const Color.fromARGB(255, 38, 166, 154); // Medium teal for 2+ hours
    } else if (hourValue >= 1) {
      cardColor = const Color.fromARGB(255, 77, 182, 172); // Light teal for 1+ hour
    } else {
      cardColor = const Color.fromARGB(255, 128, 203, 196); // Very light teal for < 1 hour
    }

    return Card(
      color: const Color.fromRGBO(38, 38, 38, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        tileColor: const Color.fromRGBO(38, 38, 38, 1),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
                name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white
                )
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cardColor,
                  width: 1,
                ),
              ),
              child: Text(
                  hrsLogged,
                  style: TextStyle(
                    fontSize: 16,
                    color: cardColor,
                    fontWeight: FontWeight.bold,
                  )
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
                formattedDate,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF00BFA5)
                )
            ),
          ],
        ),
        trailing: SizedBox(
          width: 96,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
                    isScrollControlled: true,
                    context: context,
                    builder: (context) => EditStudyhour(
                        studyHour: studyHour,
                        rootContext: rootContext
                    ),
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}