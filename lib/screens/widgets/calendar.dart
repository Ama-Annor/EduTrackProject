import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// Define the CustomCalendar widget class
class CustomCalendar extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const CustomCalendar({Key? key, required this.onDateSelected}) : super(key: key);

  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  final CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Define firstDay and lastDay properly
  final DateTime _firstDay = DateTime(2023, 1, 1); // Start from January 1, 2023
  final DateTime _lastDay = DateTime(2025, 12, 31); // End at December 31, 2025

  @override
  void initState() {
    super.initState();
    // Ensure focusedDay is within bounds
    if (_focusedDay.isBefore(_firstDay)) {
      _focusedDay = _firstDay;
    } else if (_focusedDay.isAfter(_lastDay)) {
      _focusedDay = _lastDay;
    }
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(29, 29, 29, 1),
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              DateFormat.yMMMM().format(_focusedDay),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 13.0),
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: _firstDay,
            lastDay: _lastDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDateSelected(selectedDay);
            },
            headerVisible: false,
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Color.fromRGBO(255, 63, 23, 0.3),
                shape: BoxShape.circle,
              ),
              weekendDecoration: BoxDecoration(
                color: Color.fromRGBO(29, 29, 29, 1),
                shape: BoxShape.circle,
              ),
              defaultDecoration: BoxDecoration(
                color: Color.fromRGBO(29, 29, 29, 1),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00BFA5),
              ),
              todayTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
              outsideDecoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.white),
              defaultTextStyle: TextStyle(color: Colors.white),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.white),
              weekdayStyle: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}