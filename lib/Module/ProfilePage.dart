import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? accountCreated;
  int _userPoints = 0;
  Map<String, dynamic> _badge = {};

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final timestamp = data?['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        accountCreated =
            "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
      }

      final points = data?['points'] ?? 0;

      setState(() {
        _userPoints = points;
        _badge = getBadge(points);
      });
    }
  }

  Map<String, dynamic> getBadge(int points) {
    if (points >= 200) {
      return {
        'label': 'Eco Champion',
        'icon': Icons.workspace_premium,
        'color': Colors.green[700],
      };
    } else if (points >= 100) {
      return {
        'label': 'Gold Recycler',
        'icon': Icons.emoji_events,
        'color': Colors.amber[800],
      };
    } else if (points >= 50) {
      return {
        'label': 'Silver Recycler',
        'icon': Icons.emoji_events_outlined,
        'color': Colors.grey[700],
      };
    } else {
      return {
        'label': 'Bronze Recycler',
        'icon': Icons.military_tech,
        'color': Colors.brown[400],
      };
    }
  }

  Widget buildBadgeRow(
    String label,
    int minPoints,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Text(
            "≥ $minPoints pts",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xfff4fef4),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 1,
        title: Row(
          children: const [
            Icon(Icons.person, color: Colors.green),
            SizedBox(width: 8),
            Text('Profile'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileItem(
                        icon: Icons.email_outlined,
                        title: "Email",
                        value: user?.email ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      ProfileItem(
                        icon: Icons.badge_outlined,
                        title: "User ID",
                        value: user?.uid ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      ProfileItem(
                        icon: Icons.calendar_today,
                        title: "Account Created",
                        value: accountCreated ?? 'Loading...',
                      ),
                      const SizedBox(height: 12),
                      ProfileItem(
                        icon: Icons.star_outline,
                        title: "Points Earned",
                        value: '$_userPoints',
                      ),
                      const SizedBox(height: 12),
                      if (_badge.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                Text(
                                  " Current Badge",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  _badge['icon'],
                                  color: _badge['color'],
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _badge['label'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _badge['color'],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (_badge.isEmpty)
                        const Text(
                          "No badge earned yet.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.leaderboard, color: Colors.blue),
                          Text(
                            " Badge Levels Guide",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      buildBadgeRow(
                        "Eco Champion",
                        200,
                        Icons.workspace_premium,
                        Colors.green,
                      ),
                      buildBadgeRow(
                        "Gold Recycler",
                        100,
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                      buildBadgeRow(
                        "Silver Recycler",
                        50,
                        Icons.emoji_events_outlined,
                        Colors.grey,
                      ),
                      buildBadgeRow(
                        "Bronze Recycler",
                        0,
                        Icons.military_tech,
                        Colors.brown,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Logout"),
                      content: const Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Logout",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
