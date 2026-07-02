import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'booking_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/me/bookings');
      setState(() {
        _bookings = res.data['bookings'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final api = context.read<ApiClient>();
      await api.dio.post('/bookings/$bookingId/cancel');
      _fetchHistory(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final b = _bookings[index];
                return ListTile(
                  title: Text('Booking ${b['id'].toString().substring(0, 8)}...'),
                  subtitle: Text('Status: ${b['status']} | Cost: ₹${b['totalCost']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailsScreen(bookingId: b['id']),
                      ),
                    );
                  },
                  trailing: b['status'] == 'CONFIRMED'
                      ? TextButton(
                          onPressed: () => _cancelBooking(b['id']),
                          child: Text('Cancel', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.neonRed)),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
