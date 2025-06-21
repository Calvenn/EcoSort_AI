import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  IconData getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'plastic':
        return Icons.local_drink;
      case 'glass':
        return Icons.wine_bar;
      case 'metal':
        return Icons.build;
      case 'paper':
        return Icons.description;
      case 'cardboard':
        return Icons.inventory;
      default:
        return Icons.recycling;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fef4),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Row(
          children: [
            Icon(Icons.menu_book, color: Colors.green),
            Text('  Recycling Guide'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recycling_guide')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No recycling tips found."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final label = doc.id; // use document ID as label
              final tip = doc['tip'] ?? 'No tip available.';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          getIconForLabel(label),
                          color: Colors.green[800],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label[0].toUpperCase() + label.substring(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tip,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
