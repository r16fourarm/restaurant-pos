import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IncomingOrdersScreen extends StatelessWidget {
  const IncomingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('qr_orders')
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .orderBy(FieldPath.documentId);

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming QR Orders')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No pending orders'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final token = (d['table_token'] ?? '').toString();
              final items =
                  (d['items'] is List) ? (d['items'] as List) : const [];

              return ListTile(
                title: Text('Token: $token'),
                subtitle: Text('Items: ${items.length}'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await doc.reference.update({'status': 'accepted'});
                  },
                  child: const Text('Accept'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
