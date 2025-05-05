import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/controller/studyhour_controller.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';

class CreateStudyhour extends StatefulWidget {
  final BuildContext rootContext;
  final VoidCallback onStudyHourCreated;

  const CreateStudyhour({
    super.key,
    required this.rootContext,
    required this.onStudyHourCreated,
  });

  @override
  State<CreateStudyhour> createState() => _CreateStudyhourState();
}

class _CreateStudyhourState extends State<CreateStudyhour> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDuration;
  String? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  final List<String> _courses = [
    'COA',
    'Software Engineering',
    'Mobile Development',
    'Calculus',
    'Computer Science',
    'Data Structures',
    'Business Law',
    'Macroeconomics',
    'Economics',
    'Thermodynamics',
    'Other'
  ];
  final List<String> _durations = [
    '0h 30m',
    '1h 00m',
    '1h 30m',
    '2h 00m',
    '2h 30m',
    '3h 00m',
    '3h 30m',
    '4h 00m',
    '4h 30m',
    '5h 00m',
  ];
  final StudyhourController _studyhourController = StudyhourController();
  String _errorMessage = '';
  bool _isLoading = false;

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              surface: Color.fromRGBO(29, 29, 29, 1),
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

  void _createStudyHour() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCourse == null) {
        setState(() {
          _errorMessage = 'Please select a course';
        });
        return;
      }
      if (_selectedDuration == null) {
        setState(() {
          _errorMessage = 'Please select study duration';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
        final Map<String, dynamic> studyHourData = {
          'userID': currentUserEmail,
          'course': _selectedCourse,
          'hoursLogged': _selectedDuration,
          'loggedDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        };

        final result = await _studyhourController.createStudyHour(studyHourData);
        if (result) {
          if (!mounted) return;
          Navigator.pop(context);
          widget.onStudyHourCreated();
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            const SnackBar(
              content: Text('Study hours added successfully',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFF00BFA5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to add study hours';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Add Study Hours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Course',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(38, 38, 38, 1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCourse,
                    hint: const Text(
                      'Select Course',
                      style: TextStyle(color: Colors.grey),
                    ),
                    isExpanded: true,
                    dropdownColor: const Color.fromRGBO(38, 38, 38, 1),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: _courses.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCourse = newValue;
                        _errorMessage = '';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Duration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(38, 38, 38, 1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDuration,
                    hint: const Text(
                      'Select Duration',
                      style: TextStyle(color: Colors.grey),
                    ),
                    isExpanded: true,
                    dropdownColor: const Color.fromRGBO(38, 38, 38, 1),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: _durations.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedDuration = newValue;
                        _errorMessage = '';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(38, 38, 38, 1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.white),
                    ],
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                child: CustomNormButton(
                  text: 'Add Study Hours',
                  onPressed: _createStudyHour,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}