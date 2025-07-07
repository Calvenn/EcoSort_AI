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
        return '';
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
        return Colors.grey;
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

          return PageView.builder(
            itemCount: docs.length,
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final label = doc['label'];
              final tips = doc['tip'] ?? 'No tip available.';
              final examples = doc['example'] ?? '';
              final imagePath = getImageForLabel(label);
              final color = getColorForLabel(label);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
                          imagePath,
                          width: 250,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 25),
                        Text(
                          label.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          examples,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Important Guidelines:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tips,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
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
