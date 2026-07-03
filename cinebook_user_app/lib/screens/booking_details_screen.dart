import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

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
      if (mounted) {
        setState(() {
          _booking = res.data['booking'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinemaColors.deepCharcoal,
      appBar: AppBar(
        title: const Text('Ticket Details'),
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
        actions: [
          if (_booking != null && _booking!['status'] == 'CONFIRMED')
            IconButton(
              icon: const Icon(Icons.share_rounded, color: CinemaColors.offWhite),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon!')),
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: CinemaColors.neonRed));
    }
    if (_error != null) {
      return Center(
        child: Text('Error: $_error', style: const TextStyle(color: CinemaColors.neonRed)),
      );
    }
    if (_booking == null) {
      return const Center(
        child: Text('Booking not found.', style: TextStyle(color: CinemaColors.steelGray)),
      );
    }

    final show = _booking!['show'];
    final movie = show['movie'];
    final screen = show['screen'];
    final theatre = screen['theatre'];
    final seats = _booking!['seats'] as List;

    final startTime = DateTime.parse(show['startTime']).toLocal();
    final dateStr = DateFormat('EEE, d MMM yyyy').format(startTime);
    final timeStr = DateFormat('h:mm a').format(startTime);
    
    final Map<String, List<String>> seatsByCategory = {};
    for (final s in seats) {
      final seat = s['seat'];
      final category = seat['category'] ?? 'Standard';
      if (!seatsByCategory.containsKey(category)) seatsByCategory[category] = [];
      seatsByCategory[category]!.add('${seat['row']}${seat['number']}');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTicketCard(movie, show, theatre, screen, dateStr, timeStr, seatsByCategory),
          const SizedBox(height: 32),
          _buildPaymentDetails(),
          const SizedBox(height: 48), // Padding at bottom
        ],
      ),
    );
  }

  Widget _buildTicketCard(
    Map<String, dynamic> movie, 
    Map<String, dynamic> show, 
    Map<String, dynamic> theatre, 
    Map<String, dynamic> screen,
    String dateStr,
    String timeStr,
    Map<String, List<String>> seatsByCategory,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: CinemaColors.offWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          // Top half (Movie Info)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movie['posterUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      movie['posterUrl'],
                      width: 90,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_,_,_) => const SizedBox(width: 90, height: 130, child: ColoredBox(color: CinemaColors.steelGray)),
                    ),
                  )
                else
                  const SizedBox(width: 90, height: 130, child: ColoredBox(color: CinemaColors.steelGray)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie['title'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: CinemaColors.deepCharcoal,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${movie['runtimeMin']} mins • ${movie['ageRating']}',
                        style: const TextStyle(color: CinemaColors.inkCharcoal, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_booking!['status']).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusColor(_booking!['status']).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _booking!['status'],
                          style: TextStyle(
                            color: _getStatusColor(_booking!['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider Line
          Row(
            children: [
              _buildNotch(isLeft: true),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: List.generate(
                        (constraints.constrainWidth() / 15).floor(),
                        (index) => const SizedBox(
                          width: 8,
                          height: 2,
                          child: DecoratedBox(decoration: BoxDecoration(color: CinemaColors.steelGray)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildNotch(isLeft: false),
            ],
          ),
          
          // Bottom half (Details & QR)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildInfoCol('Date', dateStr)),
                    Expanded(child: _buildInfoCol('Time', timeStr)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildInfoCol('Theatre', '${theatre['name']}, ${theatre['city']}')),
                    Expanded(child: _buildInfoCol('Screen', '${screen['name']} (${show['format']})')),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seats', style: TextStyle(color: CinemaColors.steelGray, fontSize: 13)),
                      const SizedBox(height: 4),
                      ...seatsByCategory.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.key}: ', style: const TextStyle(color: CinemaColors.inkCharcoal, fontWeight: FontWeight.bold, fontSize: 16)),
                              Expanded(
                                child: Text(
                                  e.value.join(', '),
                                  style: const TextStyle(color: CinemaColors.deepCharcoal, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // QR Code Placeholder
                if (_booking!['status'] == 'CONFIRMED')
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: CinemaColors.structuralBorder, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: QRPainter(widget.bookingId),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Scan at cinema entrance',
                        style: TextStyle(color: CinemaColors.steelGray, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildNotch({required bool isLeft}) {
    return SizedBox(
      height: 32,
      width: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CinemaColors.deepCharcoal,
          borderRadius: isLeft
              ? const BorderRadius.horizontal(right: Radius.circular(16))
              : const BorderRadius.horizontal(left: Radius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: CinemaColors.steelGray, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: CinemaColors.deepCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    final payment = _booking!['payment'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CinemaColors.inkCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CinemaColors.structuralBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary', style: TextStyle(color: CinemaColors.offWhite, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(color: CinemaColors.steelGray, fontSize: 14)),
              Text('₹${(_booking!['totalCost'] / 100).toStringAsFixed(0)}', style: const TextStyle(color: CinemaColors.offWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          if (payment != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaction ID', style: TextStyle(color: CinemaColors.steelGray, fontSize: 14)),
                Text('${payment['transactionId'].toString().substring(0, 10).toUpperCase()}...', style: const TextStyle(color: CinemaColors.offWhite, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
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

class QRPainter extends CustomPainter {
  final String seed;
  QRPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = CinemaColors.deepCharcoal;
    final random = Random(seed.hashCode);
    
    // Draw 3 position markers
    _drawMarker(canvas, paint, 0, 0, size.width * 0.25);
    _drawMarker(canvas, paint, size.width * 0.75, 0, size.width * 0.25);
    _drawMarker(canvas, paint, 0, size.height * 0.75, size.width * 0.25);

    // Draw random blocks
    final gridSize = 8;
    final blockSize = size.width / gridSize;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        // Skip marker areas
        if ((i < 3 && j < 3) || (i > 4 && j < 3) || (i < 3 && j > 4)) continue;
        
        if (random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(i * blockSize, j * blockSize, blockSize, blockSize),
            paint,
          );
        }
      }
    }
  }

  void _drawMarker(Canvas canvas, Paint paint, double x, double y, double size) {
    canvas.drawRect(Rect.fromLTWH(x, y, size, size), paint);
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + size * 0.15, y + size * 0.15, size * 0.7, size * 0.7), innerPaint);
    canvas.drawRect(Rect.fromLTWH(x + size * 0.3, y + size * 0.3, size * 0.4, size * 0.4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
