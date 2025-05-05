import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/controller/studytimer_controller.dart';
import 'package:edu_track_project/screens/sub-pages/view_studylogs.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';
import 'package:edu_track_project/services/timer_service.dart';

class TimerPage extends StatefulWidget {
  final String? email;

  const TimerPage({super.key, this.email});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  double _sliderValue = 25; // Default to 25 minutes (Pomodoro standard)
  late String _userEmail;
  String? _startTime;
  String? _endTime;
  DateTime? _startDateTime;
  TextEditingController subjectController = TextEditingController();
  bool _showCustomCourse = false;
  String? _selectedCourse;
  final List<String> _courses = [
    'COA',
    'Software Engineering',
    'Mobile Development',
    'Calculus',
    'Data Structures',
    'Business Law',
    'Macroeconomics',
    'Thermodynamics',
    'Other'
  ];

  final StudytimerController _studytimerController = StudytimerController();
  final TimerService _timerService = TimerService();

  // State variables for icon colors
  Color _playIconColor = Colors.white;
  Color _pauseIconColor = Colors.white;
  Color _resetIconColor = Colors.white;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userEmail = widget.email ?? FirebaseAuth.instance.currentUser!.email!;
    _loadTimerState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save timer state when app goes to background
    if (state == AppLifecycleState.paused) {
      _saveTimerState();
    }
    // Resume timer when app comes back to foreground
    else if (state == AppLifecycleState.resumed) {
      _loadTimerState();
    }
  }

  // Save the current timer state
  void _saveTimerState() {
    if (_isRunning || _isPaused) {
      _timerService.saveTimerState(
        isRunning: _isRunning,
        startTime: _startDateTime ?? DateTime.now(),
        durationSeconds: (_sliderValue * 60).toInt(),
        remainingSeconds: _seconds,
        isPaused: _isPaused,
      );
      print('Saved timer state: running=$_isRunning, seconds=$_seconds, isPaused=$_isPaused');
    }
  }

  // Load the timer state from persistent storage
  Future<void> _loadTimerState() async {
    final wasRunning = await _timerService.wasTimerRunning();
    if (wasRunning) {
      final wasPaused = await _timerService.wasTimerPaused();

      if (wasPaused) {
        final remainingSeconds = await _timerService.getPausedTimeRemaining();
        setState(() {
          _seconds = remainingSeconds;
          _isRunning = false;
          _isPaused = true;
          _sliderValue = _seconds / 60;
          _pauseIconColor = const Color(0xFF00BFA5);
        });
        print('Loaded paused timer: seconds=$_seconds');
        return;
      }

      final timerInfo = await _timerService.getTimerInfo();
      if (timerInfo['valid']) {
        if (timerInfo['finished']) {
          // Timer completed while app was closed
          print('Timer finished while app was closed');
          _startTime = timerInfo['formattedStartTime'];
          _endTime = timerInfo['formattedEndTime'];
          _startDateTime = timerInfo['startTime'];

          // Reset the timer
          setState(() {
            _seconds = 0;
            _isRunning = false;
            _isPaused = false;
          });

          // Clear the timer state
          await _timerService.clearTimerState();

          // Show dialog to save the completed timer
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _createTimer(context);
          });
        } else {
          // Resume timer
          setState(() {
            _seconds = timerInfo['remainingSeconds'];
            _isRunning = true;
            _isPaused = false;
            _startDateTime = timerInfo['startTime'];
            _playIconColor = const Color.fromRGBO(255, 63, 23, 1);
          });
          print('Resuming timer: seconds=$_seconds');

          // Restart the timer
          _startTimer();
        }
      }
    }
  }

  Future<void> _createTimer(BuildContext context) async {
    _showCourseSelectionDialog(context);
  }

  void _showCourseSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Save Study Session',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Course',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Course selector buttons
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _courses.map((course) {
                        final isSelected = _selectedCourse == course;
                        final isOther = course == 'Other';

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCourse = course;
                              _showCustomCourse = isOther;
                              if (!isOther) {
                                subjectController.text = course;
                              } else {
                                subjectController.clear();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00BFA5)
                                  : const Color.fromRGBO(40, 40, 40, 1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00BFA5)
                                    : Colors.grey[700]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              course,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Custom course input field that appears when "Other" is selected
                    if (_showCustomCourse) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Enter Course Name',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: subjectController,
                        labelText: 'Course Name',
                        hintText: 'Enter a custom course name',
                        maxLenOfInput: 30,
                      ),
                    ],

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _saveStudySession(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Save Session',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveStudySession(BuildContext context) async {
    final courseName = subjectController.text.trim();

    if (courseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a course name',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF00BFA5),
        ),
      );
      return;
    }

    // Proceed if validation is successful
    final currentDate = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD

    final timerDetails = {
      'course': courseName,
      'startTime': _startTime ?? DateFormat('HH:mm').format(_startDateTime ?? DateTime.now()),
      'endTime': _endTime ?? DateFormat('HH:mm').format(DateTime.now()),
      'userID': _userEmail,
      'date': currentDate,
    };

    try {
      await _studytimerController.createStudytimer(timerDetails);
      if (!mounted) return;

      Navigator.pop(context); // Close the modal

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Study session saved!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    Text(
                      'Added to your study logs',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00BFA5),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );

      // Reset the form and timer state
      subjectController.clear();
      _selectedCourse = null;
      _showCustomCourse = false;
      await _timerService.clearTimerState();

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close the modal

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save study session: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _startTimer() {
    if (!_isRunning) {
      // If timer was paused, resume from current time
      if (!_isPaused) {
        _startDateTime = DateTime.now();
        _startTime = DateFormat('HH:mm').format(_startDateTime!);
        _seconds = (_sliderValue * 60).toInt();
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            _timer?.cancel();
            setState(() {
              _isRunning = false;
              _playIconColor = Colors.white;
            });
            _endTime = DateFormat('HH:mm').format(DateTime.now());
            _createTimer(context);
          }
        });
      });

      setState(() {
        _isRunning = true;
        _isPaused = false;
        _playIconColor = const Color.fromRGBO(255, 63, 23, 1);
        _pauseIconColor = Colors.white;
        _resetIconColor = Colors.white;
      });

      // Save the timer state
      _saveTimerState();
    }
  }

  void _pauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        _isPaused = true;
        _playIconColor = Colors.white;
        _pauseIconColor = const Color(0xFF00BFA5);
      });

      // Save the paused state
      _saveTimerState();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = (_sliderValue * 60).toInt();
      _isRunning = false;
      _isPaused = false;
      _playIconColor = Colors.white;
      _pauseIconColor = Colors.white;
      _resetIconColor = const Color(0xFF00BFA5);
    });

    // Clear the timer state
    _timerService.clearTimerState();
  }

  void _setTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = (_sliderValue * 60).toInt();
      _isRunning = false;
      _isPaused = false;
      _playIconColor = Colors.white;
      _pauseIconColor = Colors.white;
      _resetIconColor = Colors.white;
    });

    // Clear the timer state when setting a new timer
    _timerService.clearTimerState();
  }

  String get _formattedTime {
    int hours = _seconds ~/ 3600;
    int minutes = (_seconds % 3600) ~/ 60;
    int secs = _seconds % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
  }

  Future<void> _refreshData() async {
    // This method will be called when the refresh button is pressed
    // If timer is running, no need to do anything
    if (!_isRunning) {
      setState(() {
        // You might want to update any other data here
      });
    }
  }

  // Helper method to build preset buttons
  Widget _buildPresetButton(String label, double minutes) {
    final isSelected = _sliderValue == minutes;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sliderValue = minutes;
          _seconds = (minutes * 60).toInt();
          _isRunning = false;
          _isPaused = false;
          _playIconColor = Colors.white;
          _pauseIconColor = Colors.white;
          _resetIconColor = Colors.white;
        });
        _timerService.clearTimerState();
      },
      child: Container(
        width: 70,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BFA5)
              : const Color.fromRGBO(40, 40, 40, 1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00BFA5)
                : Colors.grey,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        title: const Text('Study Timer',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 26),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          // Updated study logs button with text label
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewStudyHourLogs(email: _userEmail),
                  ),
                );
              },
              icon: const Icon(
                Icons.bar_chart,
                color: Color(0xFF00BFA5),
              ),
              label: const Text(
                'Study Logs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0), // Increased bottom padding to avoid nav bar overlap
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Timer presets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPresetButton('25m', 25),
                  _buildPresetButton('45m', 45),
                  _buildPresetButton('60m', 60),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Set Timer (minutes)',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Slider(
                value: _sliderValue,
                inactiveColor: Colors.grey,
                activeColor: const Color(0xFF00BFA5),
                min: 0,
                max: 120,
                divisions: 120,
                label: _sliderValue.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_sliderValue.toInt()} minutes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 120,
                height: 60,
                child: ElevatedButton(
                  onPressed: _setTimer,
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all(const Color(0xFF00BFA5)),
                    padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 15)),
                    shape: MaterialStateProperty.all(const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    )),
                  ),
                  child: const Text('Set Timer',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.normal)),
                ),
              ),
              const SizedBox(height: 40),
              // Main Timer Display
              Container(
                width: 280,
                height: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromRGBO(40, 40, 40, 1),
                  boxShadow: [
                    BoxShadow(
                      color: _isRunning
                          ? const Color(0xFF00BFA5).withOpacity(0.3)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          color: _isRunning
                              ? const Color.fromRGBO(255, 63, 23, 1)
                              : const Color(0xFF00BFA5),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.restart_alt,
                                size: 32, color: _resetIconColor),
                            onPressed: _resetTimer,
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.play_arrow,
                                size: 32, color: _playIconColor),
                            onPressed: _startTimer,
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.pause,
                                size: 32, color: _pauseIconColor),
                            onPressed: _pauseTimer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRunning
                            ? const Color.fromRGBO(255, 63, 23, 1)
                            : (_isPaused ? Colors.amber : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isRunning
                          ? "Timer Running"
                          : (_isPaused ? "Timer Paused" : "Timer Ready"),
                      style: TextStyle(
                        color: _isRunning
                            ? const Color.fromRGBO(255, 63, 23, 1)
                            : (_isPaused ? Colors.amber : Colors.grey),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50), // Extra space at the bottom
            ],
          ),
        ),
      ),
    );
  }
}