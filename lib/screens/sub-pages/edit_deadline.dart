import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/deadline_controller.dart';
import 'package:edu_track_project/model/deadline_model.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';

class EditDeadline extends StatefulWidget {
  final BuildContext rootContext;
  final Deadline deadline;

  const EditDeadline({
    super.key,
    required this.rootContext,
    required this.deadline
  });

  @override
  State<EditDeadline> createState() => _EditDeadlineState();
}

class _EditDeadlineState extends State<EditDeadline> {
  TextEditingController subjectController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();
  TimeOfDay _loggedTime = const TimeOfDay(hour: 0, minute: 0);
  late User _user;
  final DeadlineController _deadlineController = DeadlineController();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;

    // Initialize with the current deadline values
    subjectController.text = widget.deadline.title;
    descriptionController.text = widget.deadline.description;
    _selectedDate = DateTime.parse(widget.deadline.dueDate);
    _loggedTime = _convertStringToTimeOfDay(widget.deadline.reminderTime);
  }

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  TimeOfDay _convertStringToTimeOfDay(String time) {
    final regex = RegExp(r'(\d+)h (\d+)m');
    final match = regex.firstMatch(time);
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      return TimeOfDay(hour: hour, minute: minute);
    } else {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025),
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

  void _updateDeadline(BuildContext context) async {
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

    // If validation passes, proceed to update deadline
    final deadlineDetails = {
      'title': subject,
      'description': description,
      'dueDate': _selectedDate.toLocal().toString().split(' ')[0],
      'userID': _user.email,
      'setReminder': widget.deadline.setReminder, // Maintain existing value
      'reminderTime': _formatTimeWithoutAmPm(_loggedTime),
    };

    try {
      final result = await _deadlineController.updateDealine(
          deadlineDetails,
          widget.deadline.deadline_id
      );

      if (result) {
        // Show success message
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Deadline updated successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Close the edit screen
        Navigator.pop(context);
      } else {
        throw Exception('Failed to update deadline');
      }
    } catch (e) {
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update deadline: $e',
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
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        elevation: 0,
        title: const Text(
          'Edit Deadline',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00BFA5),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
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
                  text: 'Update Deadline',
                  onPressed: () => _updateDeadline(context),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}