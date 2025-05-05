import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:edu_track_project/controller/deadline_controller.dart';
import 'package:edu_track_project/model/deadline_model.dart';
import 'package:edu_track_project/screens/widgets/deadline_modal.dart';
import 'package:edu_track_project/screens/sub-pages/settings.dart';
import 'package:edu_track_project/screens/widgets/deadline_card.dart';
import 'package:edu_track_project/screens/widgets/stats_card.dart';
import 'package:http/http.dart' as http;
import 'package:edu_track_project/main.dart' show flutterLocalNotificationsPlugin;

class DashboardPage extends StatefulWidget {
  final String email;
  const DashboardPage({super.key, required this.email});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DeadlineController _deadlineController = DeadlineController();
  late Future<List<Deadline>> _deadlines;
  late Future<String> _advice;

  @override
  void initState() {
    super.initState();
    _deadlines = _fetchData();
    _advice = fetchAdvice();

    // Check for upcoming deadlines when dashboard loads
    checkUpcomingDeadlines();
  }

  Future<List<Deadline>> _fetchData() async {
    return await _deadlineController.getAllDeadlines(widget.email);
  }

  Future<String> fetchAdvice() async {
    final response = await http.get(Uri.parse('https://api.adviceslip.com/advice'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['slip']['advice'];
    } else {
      throw Exception('Failed to load advice');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _deadlines = _fetchData();
      _advice = fetchAdvice();
    });

    // Check for upcoming deadlines on refresh
    checkUpcomingDeadlines();
  }

  // Method to check for upcoming deadlines and show notifications
  Future<void> checkUpcomingDeadlines() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    try {
      // Get deadlines due tomorrow
      final deadlines = await _deadlineController.getAllDeadlines(widget.email);
      final tomorrowDeadlines = deadlines.where((deadline) {
        // Parse the due date
        final dueDate = DateTime.parse(deadline.dueDate);

        // Check if it's due tomorrow
        return dueDate.year == tomorrow.year &&
            dueDate.month == tomorrow.month &&
            dueDate.day == tomorrow.day;
      }).toList();

      // Show notification if there are deadlines due tomorrow
      if (tomorrowDeadlines.isNotEmpty) {
        // Android notification details
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'deadline_reminders_channel',
          'Deadline Reminders',
          channelDescription: 'Reminders for upcoming deadlines',
          importance: Importance.max,
          priority: Priority.high,
        );

        // iOS notification details
        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        // Platform-specific notification details
        const NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Create different messages based on number of deadlines
        final message = tomorrowDeadlines.length == 1
            ? '${tomorrowDeadlines[0].title} is due tomorrow!'
            : 'You have ${tomorrowDeadlines.length} deadlines due tomorrow!';

        // Show the notification
        await flutterLocalNotificationsPlugin.show(
          2, // Different ID from other notifications
          'Deadline Reminder',
          message,
          platformDetails,
        );
      }
    } catch (e) {
      print('Error checking upcoming deadlines: $e');
    }
  }

  void _navigateToSettingsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CSettings()),
    );
  }

  void _showNotificationDetails() async {
    final preferences = await _fetchNotificationPreferences();
    final advice = await fetchAdvice();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Motivational Quote',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  'https://zenquotes.io/api/image',
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.error,
                        size: 30,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (preferences != null &&
                  preferences['studyTipReminders'] == true) ...[
                const Text(
                  'Advice for the day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  advice,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchNotificationPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();
        if (docSnapshot.exists) {
          return docSnapshot.data();
        } else {
          print('No document found');
          return null;
        }
      } else {
        print('No user logged in');
        return null;
      }
    } catch (e) {
      print('Error fetching notification preferences: $e');
      return null;
    }
  }

  void _showDeadlineModal(Deadline deadline) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DeadlineModal(
          task: deadline.toMap(),
          onDeadlineChanged: _refreshData, // Pass the refresh callback
        );
      },
    ).then((_) {
      // Refresh data when modal is closed
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: false,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 25,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.normal,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: _refreshData,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () => _navigateToSettingsPage(context),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: _showNotificationDetails,
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
            bottom: const TabBar(
                tabAlignment: TabAlignment.fill,
                dividerColor: Color.fromRGBO(29, 29, 29, 1),
                labelColor: Color(0xFF00BFA5),
                indicatorColor: Color(0xFF00BFA5),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 1.0,
                labelStyle: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.normal,
                ),
                unselectedLabelColor: Colors.white,
                tabs: [
                  Tab(
                    text: 'Recently',
                  ),
                  Tab(
                    text: 'Week',
                  ),
                ]),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              child: Padding(
                // Add extra bottom padding to avoid overlap with navigation bar
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: TabBarView(children: [
                        StatsCard(value: 'today', email: widget.email),
                        StatsCard(value: 'week', email: widget.email),
                      ]),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Upcoming Deadlines',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    FutureBuilder<List<Deadline>>(
                      future: _deadlines,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 150,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00BFA5),
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return SizedBox(
                            height: 150,
                            child: Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return SizedBox(
                            height: 150,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.event_note,
                                    color: Color(0xFF00BFA5),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No deadlines yet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          final deadlines = snapshot.data!;
                          // Sort deadlines by date (closest first)
                          deadlines.sort((a, b) =>
                              DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate))
                          );

                          return ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 140,
                              maxHeight: 170,
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: deadlines.length,
                              itemBuilder: (context, index) {
                                final deadline = deadlines[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: GestureDetector(
                                    onTap: () => _showDeadlineModal(deadline),
                                    child: SizedBox(
                                      width: 200,
                                      child: DeadlineCard(deadline: deadline),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quote of the Day',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        'https://zenquotes.io/api/image',
                        width: 352,
                        height: 110, // Reduced height to avoid overlap
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 352,
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(38, 38, 38, 1),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.format_quote,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Quote not available',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Add extra space at bottom to avoid overlap with navigation bar
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}