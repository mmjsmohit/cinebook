import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import '../blocs/seat_map_bloc.dart';
import 'payment_screen.dart';

class SeatMapScreen extends StatelessWidget {
  final String showId;
  const SeatMapScreen({super.key, required this.showId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SeatMapBloc(api: context.read<ApiClient>())..add(LoadSeats(showId)),
      child: _SeatMapView(showId: showId),
    );
  }
}

class _SeatMapView extends StatefulWidget {
  final String showId;
  const _SeatMapView({required this.showId});
  @override
  State<_SeatMapView> createState() => _SeatMapViewState();
}

class _SeatMapViewState extends State<_SeatMapView> {
  final ScrollController _scrollController = ScrollController();
  final TransformationController _transformationController = TransformationController();

  Map<String, Map<String, List<dynamic>>> _groupSeats(List<dynamic> seats) {
    // category -> row -> list of seats
    final Map<String, Map<String, List<dynamic>>> grouped = {};
    for (final seat in seats) {
      final category = seat['category'] ?? 'UNKNOWN';
      final row = seat['row'] ?? '';
      if (!grouped.containsKey(category)) grouped[category] = {};
      if (!grouped[category]!.containsKey(row)) grouped[category]![row] = [];
      grouped[category]![row]!.add(seat);
    }
    
    // Sort rows alphabetically, and seats by number
    for (final category in grouped.keys) {
      final sortedRows = grouped[category]!.keys.toList()..sort();
      final Map<String, List<dynamic>> sortedRowMap = {};
      for (final row in sortedRows) {
        final rowSeats = grouped[category]![row]!;
        rowSeats.sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
        sortedRowMap[row] = rowSeats;
      }
      grouped[category] = sortedRowMap;
    }
    
    // Sort categories: RECLINER, PREMIUM, STANDARD, FRONT (or reverse based on standard mapping)
    // Actually, usually higher priced categories are at the back. We'll just rely on insertion order or sort if needed.
    return grouped;
  }

  double _calculateTotal(List<dynamic> seats, Map<String, DateTime> heldSeats) {
    double total = 0;
    for (final seat in seats) {
      if (heldSeats.containsKey(seat['id'])) {
        total += (seat['price'] as num).toDouble();
      }
    }
    return total / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinemaColors.deepCharcoal,
      appBar: AppBar(
        title: const Text('Select Seats'),
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
      ),
      body: BlocConsumer<SeatMapBloc, SeatMapState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error!, style: const TextStyle(color: Colors.white)),
              backgroundColor: CinemaColors.neonRed,
            ));
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.seats.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: CinemaColors.neonRed));
          }

          final groupedSeats = _groupSeats(state.seats);
          final totalPrice = _calculateTotal(state.seats, state.heldSeats);
          final selectedCount = state.heldSeats.length;

          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 2.5,
                  boundaryMargin: const EdgeInsets.all(100),
                  constrained: false,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 100, top: 40, left: 40, right: 40),
                    child: Column(
                      children: [
                        _buildScreenCurve(),
                        const SizedBox(height: 48),
                        ...groupedSeats.entries.map((catEntry) {
                          final category = catEntry.key;
                          final rowMap = catEntry.value;
                          final sampleSeat = rowMap.values.first.first;
                          final price = sampleSeat['price'];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '$category - ₹${(price / 100).toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: CinemaColors.steelGray,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...rowMap.entries.map((rowEntry) {
                                final row = rowEntry.key;
                                final seatsInRow = rowEntry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                          row,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: CinemaColors.steelGray,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Wrap(
                                        spacing: 8,
                                        children: seatsInRow.map((seat) {
                                          return _buildSeat(context, seat, state);
                                        }).toList(),
                                      ),
                                      const SizedBox(width: 48), // Padding for right side
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              
              _buildLegend(),
              _buildBottomBar(context, selectedCount, totalPrice, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScreenCurve() {
    return Column(
      children: [
        CustomPaint(
          size: const Size(280, 40),
          painter: ScreenPainter(),
        ),
        const SizedBox(height: 12),
        const Text(
          'SCREEN THIS WAY',
          style: TextStyle(
            color: CinemaColors.steelGray,
            fontSize: 10,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSeat(BuildContext context, dynamic seat, SeatMapState state) {
    final seatId = seat['id'];
    final seatState = seat['state']; 
    final isMyHold = state.heldSeats.containsKey(seatId);

    Color bgColor = CinemaColors.deepCharcoal;
    Color borderColor = CinemaColors.steelGray.withValues(alpha: 0.3);
    Color textColor = CinemaColors.offWhite;
    List<BoxShadow>? shadows;

    if (seatState == 'booked' || (seatState == 'held' && !isMyHold)) {
      bgColor = CinemaColors.inkCharcoal;
      borderColor = CinemaColors.structuralBorder;
      textColor = CinemaColors.steelGray.withValues(alpha: 0.5);
    } else if (isMyHold) {
      bgColor = CinemaColors.neonRed.withValues(alpha: 0.15);
      borderColor = CinemaColors.neonRed;
      textColor = CinemaColors.neonRed;
      shadows = [
        BoxShadow(
          color: CinemaColors.neonRed.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        )
      ];
    } else {
      borderColor = CinemaColors.successGreen.withValues(alpha: 0.7);
      textColor = CinemaColors.successGreen;
    }

    return GestureDetector(
      onTap: seatState == 'free' ? () {
        context.read<SeatMapBloc>().add(ToggleSeatSelection(seatId));
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isMyHold ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: shadows,
        ),
        child: Center(
          child: Text(
            '${seat['number']}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: CinemaColors.inkCharcoal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Available', CinemaColors.deepCharcoal, CinemaColors.successGreen.withValues(alpha: 0.7)),
          const SizedBox(width: 24),
          _buildLegendItem('Selected', CinemaColors.neonRed.withValues(alpha: 0.15), CinemaColors.neonRed, glow: true),
          const SizedBox(width: 24),
          _buildLegendItem('Sold', CinemaColors.inkCharcoal, CinemaColors.structuralBorder),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color borderColor, {bool glow = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: glow ? 2 : 1),
            borderRadius: BorderRadius.circular(4),
            boxShadow: glow ? [
              BoxShadow(
                color: CinemaColors.neonRed.withValues(alpha: 0.3),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ] : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: CinemaColors.offWhite, fontSize: 12)),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, int count, double total, SeatMapState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: CinemaColors.deepCharcoal,
        border: Border(top: BorderSide(color: CinemaColors.structuralBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count > 0 ? '$count Seats Selected' : 'No Seats Selected',
                  style: const TextStyle(color: CinemaColors.steelGray, fontSize: 13),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '₹${total.toStringAsFixed(0)}',
                    key: ValueKey<double>(total),
                    style: const TextStyle(
                      color: CinemaColors.offWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: count > 0 ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      showId: widget.showId,
                      seatIds: state.heldSeats.keys.toList().cast<String>(),
                    ),
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: CinemaColors.neonRed,
                disabledBackgroundColor: CinemaColors.structuralBorder,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: count > 0 ? 8 : 0,
                shadowColor: CinemaColors.neonRed.withValues(alpha: 0.5),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CinemaColors.warmAmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2, 
      0, 
      size.width, 
      size.height
    );

    // Add a slight glow effect
    final glowPaint = Paint()
      ..color = CinemaColors.warmAmber.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
