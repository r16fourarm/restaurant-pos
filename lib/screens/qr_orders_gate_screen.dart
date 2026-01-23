import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QrOrdersGateScreen extends StatelessWidget {
  const QrOrdersGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/incomingOrders');
      } else {
        Navigator.pushReplacementNamed(context, '/posLogin');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
