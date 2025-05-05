import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/deadline_controller.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';

class AddDeadline extends StatefulWidget {
  final BuildContext rootContext;
  final VoidCallback onDeadlineCreated;

  const AddDeadline({
    super.key,
    required this.rootContext,
    required this.onDeadlineCreated
  });

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

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    dateLoggedController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              surface: Color.fromRGBO(38, 38, 38, 1),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color.fromRGBO(29, 29, 29, 1),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatTimeWithoutAmPm(TimeOfDay time) {
    final hour = time.hour.toString();
    final minute = time.minute.toString().padLeft(2, '0');
    return '${hour}h ${minute}m';
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _loggedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              surface: Color.fromRGBO(38, 38, 38, 1),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color.fromRGBO(29, 29, 29, 1),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked != null && picked != _loggedTime) {
      setState(() {
        _loggedTime = picked;
      });
    }
  }

  void _createDeadline(BuildContext context) async {
    // Perform validation
    String subject = subjectController.text.trim();
    String description = descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Subject and description cannot be empty',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (subject.split(' ').length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Subject cannot be more than 3 words',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If validation passes, proceed to create deadline
    final String userEmail = _user.email ?? '';
    print('Creating deadline for user: $userEmail');

    final deadlineDetails = {
      'title': subject,
      'description': description,
      'dueDate': _selectedDate.toLocal().toString().split(' ')[0],
      'userID': userEmail,
      'setReminder': 'false',
      'reminderTime': _formatTimeWithoutAmPm(_loggedTime),
    };

    print('Deadline details: $deadlineDetails');

    try {
      final result = await _deadlineController.createDeadline(deadlineDetails);
      print('Create deadline result: $result');

      if (result) {
        // Show success message
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Deadline created successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Close the modal and refresh the list
        Navigator.pop(context);

        // Call the callback to refresh the deadline list
        widget.onDeadlineCreated();
      } else {
        throw Exception('Failed to create deadline');
      }
    } catch (e) {
      print('Error creating deadline: $e');
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create deadline: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
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
                  color: Color(0xFF00BFA5),
                ),
              ),
            ),
            const SizedBox(height: 40),
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
                onPressed: () => _createDeadline(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}