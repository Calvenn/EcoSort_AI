import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  String getImageForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'plastic & metal waste':
        return 'assets/recycle-bin(Orange).png';
      case 'paper waste':
        return 'assets/recycle-bin(Blue).png';
      case 'glass waste':
        return 'assets/recycle-bin(Brown).png';
      default:
        return 'assets/default-bin.png';
    }
  }

  Color getColorForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'plastic & metal waste':
        return Colors.orange;
      case 'paper waste':
        return Colors.blue[800]!;
      case 'glass waste':
        return Colors.brown[700]!;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fef4),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: Colors.green),
            SizedBox(width: 8),
            Text('Recycling Guide', style: TextStyle(color: Colors.black)),
          ],
        ),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75, // increase height room
              ),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final label = doc['label'];
                final tips = doc['tip'] ?? 'No tip available.';
                final examples = doc['example'] ?? '';
                final imagePath = getImageForLabel(label);
                final color = getColorForLabel(label);

                return Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            examples,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Important Guidelines:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tips,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
