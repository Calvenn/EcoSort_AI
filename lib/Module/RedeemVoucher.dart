import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  Future<int> _getUserPoints() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['points'] ?? 0;
  }

  Future<void> _redeemVoucher(String voucherId, int cost) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final userDoc = await userRef.get();
    int currentPoints = userDoc.data()?['points'] ?? 0;

    if (currentPoints >= cost) {
      await userRef.update({'points': currentPoints - cost});
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('redeemed')
          .add({
            'voucherId': voucherId,
            'timestamp': FieldValue.serverTimestamp(),
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redeem Vouchers')),
      body: FutureBuilder<int>(
        future: _getUserPoints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Failed to load user points."));
          }

          final userPoints = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Your Points: $userPoints",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vouchers')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No vouchers available."),
                      );
                    }

                    final vouchers = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: vouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = vouchers[index];
                        final data = voucher.data() as Map<String, dynamic>?;

                        if (data == null) {
                          return const ListTile(
                            title: Text("Invalid voucher data"),
                          );
                        }

                        final name = data['name'] ?? 'No Name';
                        final description =
                            data['description'] ?? 'No Description';
                        final int cost = (data['cost'] is int)
                            ? data['cost']
                            : int.tryParse(data['cost'].toString()) ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text("$description\nCost: $cost points"),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              onPressed: userPoints >= cost
                                  ? () async {
                                      await _redeemVoucher(voucher.id, cost);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("Redeemed $name"),
                                        ),
                                      );
                                      setState(
                                        () {},
                                      ); 
                                    }
                                  : null,
                              child: const Text("Redeem"),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
