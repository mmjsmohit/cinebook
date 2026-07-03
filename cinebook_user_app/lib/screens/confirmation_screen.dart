import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ConfirmationScreen extends StatefulWidget {
  final String bookingId;
  const ConfirmationScreen({super.key, required this.bookingId});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = res.data['booking'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // We still show success even if fetching details fails, as payment went through
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinemaColors.deepCharcoal,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back to payment
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CinemaColors.successGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSuccessAnimation(),
                  const SizedBox(height: 32),
                  if (_booking != null) ...[
                    _buildTicketSummary().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                    const SizedBox(height: 48),
                  ],
                  _buildActionButtons().animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                ],
              ),
            ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CinemaColors.successGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: CinemaColors.successGreen,
            size: 80,
          ),
        )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        Text(
          'Payment Successful!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: CinemaColors.offWhite,
              ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        Text(
          'Booking ID: ${widget.bookingId}',
          style: const TextStyle(
            color: CinemaColors.steelGray,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildTicketSummary() {
    final show = _booking!['show'];
    final movie = show['movie'];
    final screen = show['screen'];
    final theatre = screen['theatre'];
    final startTime = DateTime.parse(show['startTime']).toLocal();
    final seats = _booking!['seats'] as List<dynamic>? ?? [];
    
    // Group seats by category for display
    final Map<String, List<String>> seatsByCategory = {};
    for (final bookedSeat in seats) {
      // The backend returns an array of BookedSeat objects, which contain the actual Seat object
      final seat = bookedSeat['seat'] ?? bookedSeat;
      final category = seat['category'] ?? 'Standard';
      if (!seatsByCategory.containsKey(category)) {
        seatsByCategory[category] = [];
      }
      seatsByCategory[category]!.add('${seat['row']}${seat['number']}');
    }

    return Container(
      decoration: BoxDecoration(
        color: CinemaColors.inkCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CinemaColors.structuralBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Movie Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movie['posterUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      movie['posterUrl'],
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_,_,_) => const SizedBox(width: 70, height: 100, child: ColoredBox(color: CinemaColors.deepCharcoal)),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie['title'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: CinemaColors.offWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${show['format']} • ${show['language']}',
                        style: const TextStyle(color: CinemaColors.successGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Ticket Tear Line
          Row(
            children: [
              _buildTicketNotch(isLeft: true),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: List.generate(
                        (constraints.constrainWidth() / 10).floor(),
                        (index) => const SizedBox(
                          width: 5,
                          height: 1,
                          child: DecoratedBox(decoration: BoxDecoration(color: CinemaColors.structuralBorder)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildTicketNotch(isLeft: false),
            ],
          ),
          
          // Show Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoBlock('Date', DateFormat('EEE, d MMM').format(startTime)),
                    ),
                    Expanded(
                      child: _buildInfoBlock('Time', DateFormat('hh:mm a').format(startTime)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoBlock('Theatre', theatre['name'] ?? ''),
                    ),
                    Expanded(
                      child: _buildInfoBlock('Screen', screen['name'] ?? ''),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Seats
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seats', style: TextStyle(color: CinemaColors.steelGray, fontSize: 12)),
                      const SizedBox(height: 4),
                      ...seatsByCategory.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.key}: ', style: const TextStyle(color: CinemaColors.steelGray, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  e.value.join(', '),
                                  style: const TextStyle(color: CinemaColors.offWhite, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTicketNotch({required bool isLeft}) {
    return SizedBox(
      height: 20,
      width: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CinemaColors.deepCharcoal,
          borderRadius: isLeft
              ? const BorderRadius.horizontal(right: Radius.circular(10))
              : const BorderRadius.horizontal(left: Radius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: CinemaColors.steelGray, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: CinemaColors.offWhite,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to Booking Details (we will create this in the next task)
              // For now, return to home
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CinemaColors.neonRed,
              foregroundColor: CinemaColors.offWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text('View Tickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: TextButton.styleFrom(
              foregroundColor: CinemaColors.steelGray,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Return to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
