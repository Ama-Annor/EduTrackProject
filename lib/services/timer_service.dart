import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TimerService {
  // Keys for SharedPreferences
  static const String _timerRunningKey = 'timer_running';
  static const String _startTimeKey = 'timer_start_time';
  static const String _durationKey = 'timer_duration';
  static const String _pausedTimeKey = 'timer_paused_time';
  static const String _isPausedKey = 'timer_is_paused';

  // Save timer state when app goes to background
  Future<void> saveTimerState({
    required bool isRunning,
    required DateTime startTime,
    required int durationSeconds,
    required int remainingSeconds,
    required bool isPaused,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_timerRunningKey, isRunning);
    await prefs.setString(_startTimeKey, startTime.toIso8601String());
    await prefs.setInt(_durationKey, durationSeconds);

    // If timer is paused, save the remaining seconds
    if (isPaused) {
      await prefs.setInt(_pausedTimeKey, remainingSeconds);
      await prefs.setBool(_isPausedKey, true);
    } else {
      await prefs.remove(_pausedTimeKey);
      await prefs.setBool(_isPausedKey, false);
    }

    print('Timer state saved: isRunning=$isRunning, startTime=$startTime, duration=$durationSeconds, isPaused=$isPaused');
  }

  // Clear the timer state
  Future<void> clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerRunningKey);
    await prefs.remove(_startTimeKey);
    await prefs.remove(_durationKey);
    await prefs.remove(_pausedTimeKey);
    await prefs.remove(_isPausedKey);
    print('Timer state cleared');
  }

  // Check if a timer was running
  Future<bool> wasTimerRunning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_timerRunningKey) ?? false;
  }

  // Check if timer was paused
  Future<bool> wasTimerPaused() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPausedKey) ?? false;
  }

  // Get remaining seconds for a paused timer
  Future<int> getPausedTimeRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pausedTimeKey) ?? 0;
  }

  // Get the time information for a previously running timer
  Future<Map<String, dynamic>> getTimerInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final startTimeStr = prefs.getString(_startTimeKey);
    final durationSeconds = prefs.getInt(_durationKey) ?? 0;

    if (startTimeStr == null) {
      return {
        'valid': false,
        'remainingSeconds': 0,
        'startTime': null,
        'endTime': null,
      };
    }

    final startTime = DateTime.parse(startTimeStr);
    final now = DateTime.now();

    // Was the timer paused?
    final isPaused = prefs.getBool(_isPausedKey) ?? false;
    if (isPaused) {
      final remainingSeconds = prefs.getInt(_pausedTimeKey) ?? 0;
      return {
        'valid': true,
        'remainingSeconds': remainingSeconds,
        'elapsed': durationSeconds - remainingSeconds,
        'startTime': startTime,
        'isPaused': true,
        'finished': false,
      };
    }

    // Calculate how much time has elapsed
    final elapsedSeconds = now.difference(startTime).inSeconds;
    final remainingSeconds = durationSeconds - elapsedSeconds;

    // Check if timer has finished
    final finished = remainingSeconds <= 0;

    // If timer has finished, calculate end time
    final endTime = finished ?
    startTime.add(Duration(seconds: durationSeconds)) :
    null;

    final formattedStartTime = DateFormat('HH:mm').format(startTime);
    final formattedEndTime = endTime != null ?
    DateFormat('HH:mm').format(endTime) :
    null;

    return {
      'valid': true,
      'remainingSeconds': finished ? 0 : remainingSeconds,
      'elapsed': elapsedSeconds > durationSeconds ? durationSeconds : elapsedSeconds,
      'startTime': startTime,
      'endTime': endTime,
      'formattedStartTime': formattedStartTime,
      'formattedEndTime': formattedEndTime,
      'finished': finished,
      'isPaused': false,
    };
  }
}