import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/deadline_controller.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';

class AddDeadline extends StatefulWidget {
  final BuildContext rootContext;
  final VoidCallback onDeadlineCreated;

  const AddDeadline({super.key, required this.rootContext, required this.onDeadlineCreated});

  @override
  State<AddDeadline> createState() => _AddDeadlineState();
}

class _AddDeadlineState extends State<AddDeadline> {
  TextEditingController subjectController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateLoggedController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();
  TimeOfDay _loggedTime = const TimeOfDay(hour: 0, minute: 0);
  late User _user;
  final DeadlineController _deadlineController = DeadlineController();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
  }

  Future<void> _selectDate(BuildContext context) async {
    print('Tapped on date ListTile');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2025, 12, 31),
    );
    print('Picked date: $picked');
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        print('Updated selectedDate to: $_selectedDate');
      });
    } else {
      print('No new date picked or same as current');
    }
  }

  String _formatTimeWithoutAmPm(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(1, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${hour}h ${minute}m';
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _loggedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _loggedTime) {
      setState(() {
        _loggedTime = picked;
      });
    }
  }

  void _CreateDeadline(BuildContext context) async {
    String subject = subjectController.text.trim();
    String description = descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject and/or description cannot be empty',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (subject.split(' ').length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject cannot be more than 3 words',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    final deadlineDetails = {
      'title': subject,
      'description': description,
      'dueDate': _selectedDate.toLocal().toString().split(' ')[0],
      'userID': _user.email,
      'setReminder': 'false',
      'reminderTime': _formatTimeWithoutAmPm(_loggedTime),
    };

    print('Saving deadline with details: $deadlineDetails');

    try {
      await _deadlineController.createDeadline(deadlineDetails);
      print('Deadline saved successfully');
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        const SnackBar(
          content: Text('Deadline created successfully',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onDeadlineCreated(); // Call the callback to refresh the parent
      Navigator.pop(context);
    } catch (e) {
      print('Error saving deadline: $e');
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Text('Failed to create deadline: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Create Deadline',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BFA5)),
              ),
            ),
            const SizedBox(height: 50),
            CustomTextField(
              controller: subjectController,
              labelText: 'Subject',
              hintText: 'Enter a valid subject',
              readOnly: false,
              maxLenOfInput: 100,
            ),
            const SizedBox(height: 30),
            CustomTextField(
              controller: descriptionController,
              labelText: 'Description',
              hintText: 'Enter a valid description',
              readOnly: false,
              maxLenOfInput: 200,
            ),
            const SizedBox(height: 30),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              tileColor: const Color.fromRGBO(38, 38, 38, 1),
              title: const Text(
                'Time:',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              subtitle: Text(
                _formatTimeWithoutAmPm(_loggedTime),
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 30),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              tileColor: const Color.fromRGBO(38, 38, 38, 1),
              title: Text(
                'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.center,
              child: CustomNormButton(
                text: 'Create Deadline',
                onPressed: () {
                  _CreateDeadline(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}