import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with RouteAware {
  bool _dropdownVisible = false;
  String _scanMessage = '';
  bool _isLoadingScans = true;
  int _userPoints = 0;
  bool _loadingPoints = true;

  @override
  void initState() {
    super.initState();
    fetchTodayScanSummary();
    fetchUserPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this page (e.g. from classify/map)
    fetchTodayScanSummary();
    fetchUserPoints();
  }

  Future<void> fetchTodayScanSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('history')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    Map<String, int> countPerType = {};
    for (final doc in snapshot.docs) {
      final type = doc['type'];
      countPerType[type] = (countPerType[type] ?? 0) + 1;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingScans = false;
      if (countPerType.isEmpty) {
        _scanMessage = "You haven’t scanned anything today. Give it a try!";
      } else {
        _scanMessage = countPerType.entries
            .map((e) {
              return "• ${e.value} ${e.key} item${e.value > 1 ? 's' : ''}";
            })
            .join("\n");
        _scanMessage =
            "Today's activity:\n$_scanMessage\nDon't forget to rinse recyclables!";
      }
    });
  }

  Future<void> fetchUserPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      _userPoints = (snapshot.data()?['points'] ?? 0) as int;
      _loadingPoints = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fef4),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.front_hand, color: Colors.green[800], size: 30),
                const SizedBox(width: 8),
                Text(
                  "Welcome to EcoSort!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Make recycling easier and smarter with AI.",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            _isLoadingScans
                ? CircularProgressIndicator()
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.insights, color: Colors.green[700]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _scanMessage,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _loadingPoints
                                  ? CircularProgressIndicator(strokeWidth: 2)
                                  : Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.orange[800],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Points earned: $_userPoints",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[900],
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 20),

            // 📦 Quick Features
            Expanded(
              child: ListView(
                children: [
                  _buildCard(
                    title: "Classify Waste",
                    subtitle: "Use AI to identify and sort your waste items.",
                    icon: Icons.search,
                    onTap: () {
                      Navigator.pushNamed(context, '/classify');
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: "Recycling Centers",
                    subtitle: "Find nearby recycling centers in Penang.",
                    icon: Icons.map,
                    onTap: () {
                      Navigator.pushNamed(context, '/map');
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: "Recycling Guide",
                    subtitle: "Learn how to dispose items properly.",
                    icon: Icons.menu_book,
                    onTap: () {
                      Navigator.pushNamed(context, '/guide');
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _dropdownVisible = !_dropdownVisible;
                });
              },
              child: Row(
                children: [
                  Icon(
                    _dropdownVisible ? Icons.book : Icons.menu_book,
                    color: Colors.blue[800],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _dropdownVisible
                        ? "Hide 'Why Recycle?' section"
                        : "Do you want to learn why recycling is important?",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[800],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            if (_dropdownVisible) _buildWhyRecycleCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(icon, color: Colors.green[800]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhyRecycleCard() {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.recycling, color: Colors.green, size: 30),
                Text(
                  " Why Recycle?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Improper disposal of waste leads to pollution and resource loss. "
              "Recycling helps protect the environment and reduce landfill waste.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 12),
            Text(
              "Did You Know?",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              "• Recycling 1 aluminum can saves enough energy to power a TV for 3 hours.",
            ),
            Text(
              "• Every ton of paper recycled saves 17 trees and 7,000 gallons of water.",
            ),
            Text(
              "• Plastic can take over 400 years to decompose in landfills.",
            ),
          ],
        ),
      ),
    );
  }
}
