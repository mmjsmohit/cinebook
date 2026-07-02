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
    
    return grouped;
  }

  int _calculateTotal(List<dynamic> seats, Map<String, DateTime> heldSeats) {
    int total = 0;
    for (final seat in seats) {
      if (heldSeats.containsKey(seat['id'])) {
        total += (seat['price'] as num).toInt();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cinemaTheme = Theme.of(context).extension<CinemaThemeExtension>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Seats'),
      ),
      body: BlocConsumer<SeatMapBloc, SeatMapState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.seats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupedSeats = _groupSeats(state.seats);
          final totalPrice = _calculateTotal(state.seats, state.heldSeats);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: groupedSeats.entries.map((catEntry) {
                      final category = catEntry.key;
                      final rowMap = catEntry.value;
                      
                      // Get price from first seat in category
                      final sampleSeat = rowMap.values.first.first;
                      final price = sampleSeat['price'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              'Rs.$price  $category',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: CinemaColors.offWhite),
                            ),
                          ),
                          const Divider(height: 1, color: CinemaColors.structuralBorder),
                          const SizedBox(height: 16),
                          ...rowMap.entries.map((rowEntry) {
                            final row = rowEntry.key;
                            final seatsInRow = rowEntry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(row, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.steelGray, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: seatsInRow.map((seat) {
                                        final seatId = seat['id'];
                                        final seatState = seat['state']; // Fixed bug here!
                                        final isMyHold = state.heldSeats.containsKey(seatId);

                                        Color? bgColor;
                                        Color borderColor = cinemaTheme?.seatAvailable ?? CinemaColors.successGreen;
                                        Color textColor = cinemaTheme?.seatAvailable ?? CinemaColors.successGreen;

                                        if (seatState == 'booked') {
                                          bgColor = cinemaTheme?.seatSold ?? CinemaColors.inkCharcoal;
                                          borderColor = cinemaTheme?.seatSold ?? CinemaColors.inkCharcoal;
                                          textColor = CinemaColors.steelGray;
                                        } else if (seatState == 'held' && !isMyHold) {
                                          bgColor = cinemaTheme?.seatSold ?? CinemaColors.inkCharcoal;
                                          borderColor = cinemaTheme?.seatSold ?? CinemaColors.inkCharcoal;
                                          textColor = CinemaColors.steelGray;
                                        } else if (isMyHold) {
                                          bgColor = cinemaTheme?.seatSelected ?? CinemaColors.successGreen;
                                          textColor = CinemaColors.offWhite;
                                        }

                                        return GestureDetector(
                                          onTap: seatState == 'free' ? () {
                                            context.read<SeatMapBloc>().add(ToggleSeatSelection(seatId));
                                          } : null,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              border: Border.all(color: borderColor),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${seat['number']}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Legend
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Available', null, cinemaTheme?.seatAvailable ?? CinemaColors.successGreen),
                    const SizedBox(width: 16),
                    _buildLegendItem('Selected', cinemaTheme?.seatSelected ?? CinemaColors.successGreen, cinemaTheme?.seatSelected ?? CinemaColors.successGreen),
                    const SizedBox(width: 16),
                    _buildLegendItem('Sold', cinemaTheme?.seatSold ?? CinemaColors.inkCharcoal, cinemaTheme?.seatSold ?? CinemaColors.inkCharcoal),
                  ],
                ),
              ),

              // Bottom Bar
              if (state.heldSeats.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CinemaColors.deepCharcoal,
                    boxShadow: [BoxShadow(color: CinemaColors.inkCharcoal.withValues(alpha: 0.12), blurRadius: 4, offset: Offset(0, -2))],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CinemaColors.neonRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                showId: widget.showId,
                                seatIds: state.heldSeats.keys.toList().cast<String>(),
                              ),
                            ),
                          );
                        },
                        child: Text('Pay ₹$totalPrice', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: CinemaColors.offWhite)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color? bgColor, Color borderColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
