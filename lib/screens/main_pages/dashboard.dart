import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edu_track_project/controller/deadline_controller.dart';
import 'package:edu_track_project/model/deadline_model.dart';
import 'package:edu_track_project/screens/sub-pages/settings.dart';
import 'package:edu_track_project/screens/widgets/deadline_card.dart';
import 'package:edu_track_project/screens/widgets/stats_card.dart';
import 'package:http/http.dart' as http;

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
    //triggerNotification();
  }

  Future<List<Deadline>> _fetchData() async {
    return await _deadlineController.getAllDeadlines(widget.email);
  }

  // Future<void> triggerNotification() async {
  //   const url = 'https://us-central1-studymaster-34e00.cloudfunctions.net/send_motivational_quote';
  //   final response = await http.post(Uri.parse(url));

  //   if (response.statusCode == 200) {
  //     print('Notification sent successfully!');
  //   } else {
  //     print('Failed to send notification.');
  //   }
  // }

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
                  'https://zenquotes.io/api/image', // Replace with your image URL
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
                            Icons.settings,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => _navigateToSettingsPage(context),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_outlined,
                            color: Colors.white,
                            size: 30,
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
                    text: 'Today',
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
                padding: const EdgeInsets.all(16.0),
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
                      height: 10,
                    ),
                    FutureBuilder<List<Deadline>>(
                      future: _deadlines,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text(
                                '',
                                style: TextStyle(color: Colors.white),
                              ));
                        } else {
                          final deadlines = snapshot.data!;
                          return SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: deadlines.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: SizedBox(
                                      width: 200, // Adjust width for each card
                                      child: DeadlineCard(
                                          deadline: deadlines[index]),
                                    ),
                                  );
                                },
                              ));
                        }
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '\t\tQuote of the Day',
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
                        'https://zenquotes.io/api/image', // Replace with your image URL
                        width: 352,
                        height: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Handle image loading error
                          return Container(
                            width: 55,
                            height: 55,
                            color: Colors
                                .grey[300], // Background color for error state
                            child: Icon(
                              Icons.error, // Default meal icon
                              size: 30,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}