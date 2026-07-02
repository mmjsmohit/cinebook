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
      return Center(child: Text('Error: $_error', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.neonRed)));
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
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 120,
                color: CinemaColors.inkCharcoal,
                child: const Icon(Icons.movie, color: CinemaColors.steelGray, size: 40),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${movie['runtimeMin']} mins • ${movie['ageRating']}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.steelGray),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_booking!['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _booking!['status'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        Icon(icon, color: CinemaColors.steelGray, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: CinemaColors.steelGray)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
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
        color: CinemaColors.inkCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CinemaColors.structuralBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.steelGray)),
              Text('₹${_booking!['totalCost']}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (payment != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction ID', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.steelGray)),
                Text('${payment['transactionId'].toString().substring(0, 8)}...'),
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
        return CinemaColors.successGreen;
      case 'CANCELLED':
        return CinemaColors.neonRed;
      case 'PENDING':
        return CinemaColors.warmAmber;
      default:
        return CinemaColors.steelGray;
    }
  }
}
