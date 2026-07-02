import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';

abstract class SeatMapEvent {}
class LoadSeats extends SeatMapEvent { final String showId; LoadSeats(this.showId); }
class RefreshSeats extends SeatMapEvent {}
class HoldSeat extends SeatMapEvent { final String seatId; HoldSeat(this.seatId); }
class SeatHoldExpired extends SeatMapEvent { final String seatId; SeatHoldExpired(this.seatId); }
class StopPolling extends SeatMapEvent {}

class SeatMapState {
  final List<dynamic> seats;
  final bool isLoading;
  final String? error;
  final Map<String, DateTime> heldSeats;

  SeatMapState({this.seats = const [], this.isLoading = false, this.error, this.heldSeats = const {}});
  
  SeatMapState copyWith({List<dynamic>? seats, bool? isLoading, String? error, Map<String, DateTime>? heldSeats}) {
    return SeatMapState(
      seats: seats ?? this.seats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      heldSeats: heldSeats ?? this.heldSeats,
    );
  }
}

class SeatMapBloc extends Bloc<SeatMapEvent, SeatMapState> {
  final ApiClient api;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  String? _currentShowId;

  SeatMapBloc({required this.api}) : super(SeatMapState()) {
    on<LoadSeats>((event, emit) async {
      _currentShowId = event.showId;
      emit(state.copyWith(isLoading: true));
      await _fetchSeats(emit);
      _startPolling();
      _startCountdown();
    });

    on<RefreshSeats>((event, emit) async {
      await _fetchSeats(emit);
    });

    on<HoldSeat>((event, emit) async {
      if (_currentShowId == null) return;
      try {
        await api.dio.post('/shows/$_currentShowId/holds', data: {'seatIds': [event.seatId]});
        final newHolds = Map<String, DateTime>.from(state.heldSeats);
        newHolds[event.seatId] = DateTime.now().add(const Duration(minutes: 5));
        emit(state.copyWith(heldSeats: newHolds));
        add(RefreshSeats());
      } catch (e) {
        emit(state.copyWith(error: 'Failed to hold seat or seat taken.'));
        add(RefreshSeats());
      }
    });

    on<SeatHoldExpired>((event, emit) {
      final newHolds = Map<String, DateTime>.from(state.heldSeats);
      newHolds.remove(event.seatId);
      emit(state.copyWith(heldSeats: newHolds));
    });

    on<StopPolling>((event, emit) {
      _pollingTimer?.cancel();
      _countdownTimer?.cancel();
    });
  }

  Future<void> _fetchSeats(Emitter<SeatMapState> emit) async {
    if (_currentShowId == null) return;
    try {
      final res = await api.dio.get('/shows/$_currentShowId/seats');
      emit(state.copyWith(seats: res.data, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      add(RefreshSeats());
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final expired = state.heldSeats.entries.where((e) => e.value.isBefore(now)).toList();
      for (final e in expired) {
        add(SeatHoldExpired(e.key));
      }
    });
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}
