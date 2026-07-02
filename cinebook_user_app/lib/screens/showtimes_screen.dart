import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:intl/intl.dart';
import 'seat_map_screen.dart';

class ShowtimesScreen extends StatefulWidget {
  final String movieId;
  const ShowtimesScreen({super.key, required this.movieId});

  @override
  State<ShowtimesScreen> createState() => _ShowtimesScreenState();
}

class _ShowtimesScreenState extends State<ShowtimesScreen> {
  List<dynamic> _shows = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchShows();
  }

  Future<void> _fetchShows() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await api.dio.get('/shows?movieId=${widget.movieId}&date=$dateStr');
      setState(() {
        _shows = res.data['shows'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Map<String, List<dynamic>> _groupShowsByTheatre() {
    final Map<String, List<dynamic>> grouped = {};
    for (final show in _shows) {
      final theatreName = show['screen']?['theatre']?['name'] ?? 'Unknown Theatre';
      if (!grouped.containsKey(theatreName)) {
        grouped[theatreName] = [];
      }
      grouped[theatreName]!.add(show);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedShows = _groupShowsByTheatre();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Select Theatre & Show')),
      body: Column(
        children: [
          // Date Picker
          Container(
            height: 70,
            color: CinemaColors.inkCharcoal,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _fetchShows();
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? CinemaColors.neonRed : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? CinemaColors.neonRed : CinemaColors.structuralBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('EEE').format(date).toUpperCase(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isSelected ? CinemaColors.offWhite : CinemaColors.steelGray)),
                        Text(DateFormat('dd').format(date), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isSelected ? CinemaColors.offWhite : null)),
                        Text(DateFormat('MMM').format(date).toUpperCase(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isSelected ? CinemaColors.offWhite : CinemaColors.steelGray)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Shows
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shows.isEmpty
                    ? const Center(child: Text('No shows available for this date'))
                    : ListView.builder(
                        itemCount: groupedShows.length,
                        itemBuilder: (context, index) {
                          final theatreName = groupedShows.keys.elementAt(index);
                          final shows = groupedShows[theatreName]!;
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite_border, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(theatreName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                                      const Icon(Icons.info_outline, size: 20, color: CinemaColors.steelGray),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: shows.map((show) {
                                      final startTime = DateTime.parse(show['startTime']).toLocal();
                                      final timeStr = DateFormat('hh:mm a').format(startTime);
                                      return InkWell(
                                        onTap: () {
                                          Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => SeatMapScreen(showId: show['id']),
                                          ));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: CinemaColors.successGreen),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(timeStr, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.successGreen, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text('${show['format']} ${show['language']}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: CinemaColors.steelGray)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
