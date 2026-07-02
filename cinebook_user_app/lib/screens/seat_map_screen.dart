import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import '../blocs/seat_map_bloc.dart';

class SeatMapScreen extends StatelessWidget {
  final String showId;
  const SeatMapScreen({super.key, required this.showId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SeatMapBloc(api: context.read<ApiClient>())..add(LoadSeats(showId)),
      child: const _SeatMapView(),
    );
  }
}

class _SeatMapView extends StatefulWidget {
  const _SeatMapView();
  @override
  State<_SeatMapView> createState() => _SeatMapViewState();
}

class _SeatMapViewState extends State<_SeatMapView> {
  @override
  Widget build(BuildContext context) {
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

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: state.seats.length,
                  itemBuilder: (context, index) {
                    final seat = state.seats[index];
                    final seatId = seat['id'];
                    final status = seat['status']; // free, held, booked
                    final category = seat['category'];
                    final isMyHold = state.heldSeats.containsKey(seatId);

                    Color seatColor = Colors.grey;
                    if (status == 'booked') seatColor = Colors.red;
                    else if (status == 'held' && !isMyHold) seatColor = Colors.orange;
                    else if (isMyHold) seatColor = Colors.green;
                    else if (category == 'PREMIUM') seatColor = Colors.blue;

                    return GestureDetector(
                      onTap: status == 'free' ? () {
                        context.read<SeatMapBloc>().add(HoldSeat(seatId));
                      } : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: seatColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${seat['row']}${seat['number']}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (state.heldSeats.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black26,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${state.heldSeats.length} seats selected'),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to Payment Screen
                        },
                        child: const Text('Book'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
