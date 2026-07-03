import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:intl/intl.dart';
import 'booking_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/me/bookings');
      if (mounted) {
        setState(() {
          _bookings = res.data['bookings'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: CinemaColors.neonRed));
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final api = context.read<ApiClient>();
      await api.dio.post('/bookings/$bookingId/cancel');
      _fetchHistory(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: CinemaColors.neonRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinemaColors.deepCharcoal,
      appBar: AppBar(
        title: const Text('My Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CinemaColors.neonRed,
          labelColor: CinemaColors.offWhite,
          unselectedLabelColor: CinemaColors.steelGray,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CinemaColors.neonRed))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(isUpcoming: true),
                _buildBookingList(isUpcoming: false),
              ],
            ),
    );
  }

  Widget _buildBookingList({required bool isUpcoming}) {
    final now = DateTime.now();
    final filtered = _bookings.where((b) {
      final show = b['show'];
      if (show == null || show['startTime'] == null) return false;
      final startTime = DateTime.parse(show['startTime']).toLocal();
      if (isUpcoming) {
        return startTime.isAfter(now);
      } else {
        return startTime.isBefore(now);
      }
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_num_outlined, size: 64, color: CinemaColors.steelGray.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming tickets' : 'No past tickets',
              style: const TextStyle(color: CinemaColors.steelGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final b = filtered[index];
        return _buildBookingCard(b);
      },
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final show = booking['show'];
    final movie = show?['movie'];
    final startTimeStr = show?['startTime'];
    DateTime? startTime;
    if (startTimeStr != null) {
      startTime = DateTime.parse(startTimeStr).toLocal();
    }
    
    final status = booking['status'] as String;
    final isConfirmed = status == 'CONFIRMED';
    final isCancelled = status == 'CANCELLED';
    
    Color statusColor = CinemaColors.steelGray;
    if (isConfirmed) statusColor = CinemaColors.successGreen;
    if (isCancelled) statusColor = CinemaColors.neonRed;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(bookingId: booking['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: CinemaColors.inkCharcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CinemaColors.structuralBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: movie != null && movie['posterUrl'] != null
                        ? Image.network(
                            movie['posterUrl'],
                            width: 70,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_,_,_) => const SizedBox(width: 70, height: 100, child: ColoredBox(color: CinemaColors.deepCharcoal)),
                          )
                        : const SizedBox(width: 70, height: 100, child: ColoredBox(color: CinemaColors.deepCharcoal)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie?['title'] ?? 'Unknown Movie',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: CinemaColors.offWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (startTime != null)
                          Text(
                            DateFormat('EEE, d MMM • hh:mm a').format(startTime),
                            style: const TextStyle(color: CinemaColors.steelGray, fontSize: 13),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₹${booking['totalCost']}',
                              style: const TextStyle(
                                color: CinemaColors.offWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: CinemaColors.deepCharcoal,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: CinemaColors.structuralBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking ID: ${booking['id'].toString().substring(0, 8).toUpperCase()}',
                    style: const TextStyle(color: CinemaColors.steelGray, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (isConfirmed)
                        GestureDetector(
                          onTap: () => _cancelBooking(booking['id']),
                          child: const Text('Cancel', style: TextStyle(color: CinemaColors.neonRed, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      const SizedBox(width: 16),
                      const Text(
                        'View Details',
                        style: TextStyle(color: CinemaColors.warmAmber, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
