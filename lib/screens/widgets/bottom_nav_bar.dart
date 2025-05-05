import 'package:flutter/material.dart';
import 'package:edu_track_project/screens/main_pages/dashboard.dart';
import 'package:edu_track_project/screens/main_pages/deadlines.dart';
import 'package:edu_track_project/screens/main_pages/notes.dart';
import 'package:edu_track_project/screens/main_pages/schedules.dart';
import 'package:edu_track_project/screens/main_pages/timer.dart';

class CustomBottomNav extends StatefulWidget {
  final String email;
  const CustomBottomNav({super.key, required this.email});

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  int _selectedIndex = 0;
  late List<Widget> pages;

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.calendar_month, 'label': 'Schedules'},
    {'icon': Icons.list, 'label': 'Deadlines'},
    {'icon': Icons.note, 'label': 'Notes'},
    {'icon': Icons.timer, 'label': 'Timer'},
  ];

  @override
  void initState() {
    super.initState();
    pages = [
      DashboardPage(email: widget.email),
      SchedulesPage(email: widget.email), // Add this back
      DeadlinePage(email: widget.email),
      NotesPage(email: widget.email),
      TimerPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              height: 75,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _navItems.map((item) {
                  int index = _navItems.indexOf(item);
                  bool isSelected = index == _selectedIndex;
                  return Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'],
                            color: isSelected ? Colors.white : Colors.white70,
                            size: isSelected ? 35 : 30,
                          ),
                          Text(
                            item['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 40,
                              height: 2,
                              color: Colors.white,
                              margin: const EdgeInsets.only(top: 2),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}