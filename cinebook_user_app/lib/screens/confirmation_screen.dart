import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final String bookingId;
  const ConfirmationScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Your booking was successful!'),
            const SizedBox(height: 8),
            Text('Booking ID: $bookingId', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
