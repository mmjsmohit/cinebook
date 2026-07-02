import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/bookings/${widget.bookingId}');
      setState(() {
        _booking = res.data['booking'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }
    if (_booking == null) {
      return const Center(child: Text('Booking not found.'));
    }

    final show = _booking!['show'];
    final movie = show['movie'];
    final screen = show['screen'];
    final theatre = screen['theatre'];
    final seats = _booking!['seats'] as List;

    final startTime = DateTime.parse(show['startTime']);
    final dateStr = DateFormat('EEE, d MMM yyyy').format(startTime);
    final timeStr = DateFormat('h:mm a').format(startTime);

    final seatLabels = seats.map((s) {
      final seat = s['seat'];
      return '${seat['row']}${seat['number']}';
    }).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMovieHeader(movie),
          const SizedBox(height: 24),
          _buildDetailRow(Icons.location_on, 'Theatre', '${theatre['name']}, ${theatre['city']}'),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today, 'Date & Time', '$dateStr at $timeStr'),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.event_seat, 'Seats (${seats.length})', seatLabels),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.movie_creation, 'Screen', '${screen['name']} (${show['format']})'),
          const Divider(height: 40),
          _buildPaymentDetails(),
        ],
      ),
    );
  }

  Widget _buildMovieHeader(Map<String, dynamic> movie) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (movie['posterUrl'] != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              movie['posterUrl'],
              width: 80,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 120,
                color: Colors.grey[800],
                child: const Icon(Icons.movie, color: Colors.white54, size: 40),
              ),
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie['title'],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${movie['runtimeMin']} mins • ${movie['ageRating']}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_booking!['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _booking!['status'],
                  style: TextStyle(
                    color: _getStatusColor(_booking!['status']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    final payment = _booking!['payment'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(color: Colors.grey)),
              Text('₹${_booking!['totalCost']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          if (payment != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaction ID', style: TextStyle(color: Colors.grey)),
                Text(payment['transactionId'].toString().substring(0, 8) + '...'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
