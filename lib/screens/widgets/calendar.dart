import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CustomCalendar extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const CustomCalendar({super.key, required this.onDateSelected});

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Trigger initial date selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateSelected(_focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(29, 29, 29, 1),
        borderRadius: BorderRadius.circular(0),
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
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
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
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
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
              selectedTextStyle: TextStyle(color: Colors.white),
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