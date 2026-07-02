import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String showId;
  final List<String> seatIds;

  const PaymentScreen({super.key, required this.showId, required this.seatIds});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    try {
      final api = context.read<ApiClient>();
      
      final holdRes = await api.dio.post('/shows/${widget.showId}/holds', data: {
        'seatIds': widget.seatIds,
      });
      final holdToken = holdRes.data['holdToken'];

      final bookRes = await api.dio.post('/bookings', data: {
        'showId': widget.showId,
        'seatIds': widget.seatIds,
        'holdToken': holdToken,
      });
      final bookingId = bookRes.data['bookingId'];

      await Future.delayed(const Duration(seconds: 2));

      await api.dio.post('/payments', data: {
        'bookingId': bookingId,
        'cardNumber': '4000', 
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ConfirmationScreen(bookingId: bookingId)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing Payment...'),
                ],
              )
            : ElevatedButton(
                onPressed: _processPayment,
                child: Text('Pay for ${widget.seatIds.length} seats'),
              ),
      ),
    );
  }
}
