import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/schedule_controller.dart';
import 'package:edu_track_project/model/schedule_model.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';

class EditSchedule extends StatefulWidget {
  final Schedule schedule;
  final BuildContext rootContext;

  const EditSchedule({super.key, required this.schedule, required this.rootContext});

  @override
  State<EditSchedule> createState() => _EditScheduleState();
}

class _EditScheduleState extends State<EditSchedule> {
  final _formKey = GlobalKey<FormState>();
  final ScheduleController _scheduleController = ScheduleController();
  late TextEditingController subjectController;
  late TextEditingController courseController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController descriptionController;
  late String _priority;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    subjectController = TextEditingController(text: widget.schedule.subject);
    courseController = TextEditingController(text: widget.schedule.course);
    _selectedDate = DateTime.parse(widget.schedule.date);
    _startTime = _convertStringToTimeOfDay(widget.schedule.start);
    _endTime = _convertStringToTimeOfDay(widget.schedule.end);
    descriptionController = TextEditingController(text: widget.schedule.description);
    _priority = widget.schedule.priority;
  }

  @override
  void dispose() {
    subjectController.dispose();
    courseController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  TimeOfDay _convertStringToTimeOfDay(String time) {
    // Parse time in format "3h 00m"
    final regex = RegExp(r'(\d+)h (\d+)m');
    final match = regex.firstMatch(time);
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      return TimeOfDay(hour: hour, minute: minute);
    } else {
      // Return a default value if parsing fails
      return const TimeOfDay(hour: 9, minute: 0);
    }
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

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
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
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;

          // If end time is before start time, adjust end time
          if (_timeToMinutes(_endTime) <= _timeToMinutes(_startTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          if (_timeToMinutes(picked) > _timeToMinutes(_startTime)) {
            _endTime = picked;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'End time must be after start time',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Color(0xFF00BFA5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });
    }
  }

  // Helper method to convert TimeOfDay to minutes for easy comparison
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTimeWithoutAmPm(TimeOfDay time) {
    final hour = time.hour.toString();
    final minute = time.minute.toString().padLeft(2, '0');
    return '${hour}h ${minute}m';
  }

  void _updateSchedule() async {
    if (_validateFields()) {
      final schedule = {
        'subject': subjectController.text.trim(),
        'course': courseController.text.trim(),
        'date': _selectedDate.toLocal().toString().split(' ')[0],
        'start': _formatTimeWithoutAmPm(_startTime),
        'end': _formatTimeWithoutAmPm(_endTime),
        'description': descriptionController.text.trim(),
        'priority': _priority,
        'userID': widget.schedule.userID,
      };

      print('Updated schedule details: $schedule');

      try {
        final result = await _scheduleController.updateSchedule(
            schedule,
            widget.schedule.schedule_id
        );

        if (result) {
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            const SnackBar(
              content: Text(
                'Schedule updated successfully',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF00BFA5),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          throw Exception('Failed to update schedule');
        }
      } catch (e) {
        print('Error updating schedule: $e');
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update schedule: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _validateFields() {
    if (subjectController.text.trim().isEmpty) {
      _showError('Subject is required');
      return false;
    }

    if (subjectController.text.split(' ').length > 3) {
      _showError('Subject cannot be more than 3 words');
      return false;
    }

    if (courseController.text.trim().isEmpty) {
      _showError('Course title is required');
      return false;
    }

    if (courseController.text.split(' ').length > 3) {
      _showError('Course title cannot be more than 3 words');
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      _showError('Description is required');
      return false;
    }

    // Time validation is handled when selecting time
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        title: const Text(
          'Edit Schedule',
          style: TextStyle(
            color: Color(0xFF00BFA5),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              CustomTextField(
                controller: subjectController,
                labelText: 'Subject',
                hintText: 'Enter a subject name',
                maxLenOfInput: 40,
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: courseController,
                labelText: 'Course',
                hintText: 'Enter a course name',
                maxLenOfInput: 40,
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: descriptionController,
                labelText: 'Description',
                hintText: 'Enter a brief description',
                maxLenOfInput: 100,
              ),
              const SizedBox(height: 20),

              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                tileColor: const Color.fromRGBO(38, 38, 38, 1),
                title: Text(
                  'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF00BFA5)),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      tileColor: const Color.fromRGBO(38, 38, 38, 1),
                      title: const Text(
                        'Start Time:',
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                      subtitle: Text(
                        _formatTimeWithoutAmPm(_startTime),
                        style: const TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.access_time, color: Color(0xFF00BFA5)),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      tileColor: const Color.fromRGBO(38, 38, 38, 1),
                      title: const Text(
                        'End Time:',
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                      subtitle: Text(
                        _formatTimeWithoutAmPm(_endTime),
                        style: const TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.access_time, color: Color(0xFF00BFA5)),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
                child: Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPriorityOption('High', Colors.redAccent),
                  _buildPriorityOption('Medium', Colors.orangeAccent),
                  _buildPriorityOption('Low', Colors.greenAccent),
                ],
              ),

              const SizedBox(height: 40),

              CustomNormButton(
                text: 'Update Schedule',
                onPressed: _updateSchedule,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String value, Color color) {
    return Expanded(
      child: RadioListTile<String>(
        contentPadding: EdgeInsets.zero,
        title: Text(
          value,
          style: TextStyle(
            color: _priority == value ? color : Colors.white,
            fontSize: 14,
            fontWeight: _priority == value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        activeColor: color,
        value: value,
        groupValue: _priority,
        onChanged: (String? newValue) {
          setState(() {
            _priority = newValue!;
          });
        },
      ),
    );
  }
}