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
  Map<String, dynamic>? _movie;
  List<dynamic> _shows = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String? _selectedFormat; // e.g., '2D', '3D', 'IMAX'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final results = await Future.wait([
        api.dio.get('/movies/${widget.movieId}'),
        api.dio.get('/shows?movieId=${widget.movieId}&date=$dateStr'),
      ]);
      
      setState(() {
        _movie = results[0].data['movie'];
        _shows = results[1].data['shows'];
        _isLoading = false;
        
        // Auto-select first available format if current selection isn't valid
        final formats = _getAvailableFormats();
        if (_selectedFormat != null && !formats.contains(_selectedFormat)) {
          _selectedFormat = formats.isNotEmpty ? formats.first : null;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: CinemaColors.neonRed),
        );
      }
    }
  }

  List<String> _getAvailableFormats() {
    final formats = <String>{};
    for (final show in _shows) {
      if (show['format'] != null) {
        formats.add(show['format'].toString());
      }
    }
    return formats.toList()..sort();
  }

  Map<String, List<dynamic>> _groupShowsByTheatre() {
    final Map<String, List<dynamic>> grouped = {};
    for (final show in _shows) {
      if (_selectedFormat != null && show['format'] != _selectedFormat) {
        continue;
      }
      
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
    final formats = _getAvailableFormats();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Show'),
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Movie Header
          if (_movie != null) _buildMovieHeader(),
          
          // Date Picker
          _buildDatePicker(),
          
          // Format Filters
          if (formats.isNotEmpty) _buildFormatFilters(formats),
          
          const Divider(height: 1, color: CinemaColors.structuralBorder),
          
          // Shows List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: CinemaColors.neonRed))
                : groupedShows.isEmpty
                    ? Center(
                        child: Text(
                          'No shows available for this date/format',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: CinemaColors.steelGray),
                        ),
                      )
                    : ListView.builder(
                        itemCount: groupedShows.length,
                        itemBuilder: (context, index) {
                          final theatreName = groupedShows.keys.elementAt(index);
                          final shows = groupedShows[theatreName]!;
                          return _buildTheatreCard(theatreName, shows);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieHeader() {
    final runtime = _movie!['runtimeMin'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CinemaColors.deepCharcoal,
        border: Border(bottom: BorderSide(color: CinemaColors.structuralBorder)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _movie!['posterUrl'] != null
                ? Image.network(_movie!['posterUrl'], width: 60, height: 80, fit: BoxFit.cover, errorBuilder: (_,_,_) => const SizedBox(width: 60, height: 80, child: ColoredBox(color: CinemaColors.inkCharcoal)))
                : const SizedBox(width: 60, height: 80, child: ColoredBox(color: CinemaColors.inkCharcoal)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _movie!['title'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: CinemaColors.offWhite),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_movie!['ageRating'] != null)
                      _buildBadge(_movie!['ageRating'], color: CinemaColors.warmAmber),
                    if (_movie!['ageRating'] != null && runtime > 0)
                      const SizedBox(width: 8),
                    if (runtime > 0)
                      _buildBadge('${runtime ~/ 60}h ${runtime % 60}m', color: CinemaColors.steelGray),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: CinemaColors.inkCharcoal,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 14, // 2 weeks advance booking
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _fetchData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? CinemaColors.neonRed : CinemaColors.deepCharcoal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? CinemaColors.neonRed : CinemaColors.structuralBorder,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: CinemaColors.neonRed.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : CinemaColors.steelGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSelected 
                          ? Colors.white 
                          : (isWeekend ? CinemaColors.warmAmber : CinemaColors.offWhite),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : CinemaColors.steelGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormatFilters(List<String> formats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: CinemaColors.deepCharcoal,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Formats', null),
            const SizedBox(width: 8),
            ...formats.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(f, f),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFormat == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CinemaColors.offWhite : CinemaColors.inkCharcoal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CinemaColors.offWhite : CinemaColors.structuralBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? CinemaColors.deepCharcoal : CinemaColors.offWhite,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTheatreCard(String theatreName, List<dynamic> shows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CinemaColors.inkCharcoal,
        border: const Border(
          bottom: BorderSide(color: CinemaColors.structuralBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.theaters, size: 20, color: CinemaColors.steelGray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  theatreName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CinemaColors.offWhite,
                      ),
                ),
              ),
              const Icon(Icons.info_outline, size: 18, color: CinemaColors.steelGray),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: shows.map((show) {
              final startTime = DateTime.parse(show['startTime']).toLocal();
              final timeStr = DateFormat('hh:mm a').format(startTime);
              
              // Mock availability calculation for UI polish
              // In a real app, this would come from the API payload
              final capacity = 100; // Mock
              final booked = (show['id'].hashCode % 100); // Deterministic mock
              final availability = 1.0 - (booked / capacity);
              
              Color statusColor;
              if (availability > 0.5) {
                statusColor = CinemaColors.successGreen;
              } else if (availability > 0.1) {
                statusColor = CinemaColors.warmAmber;
              } else {
                statusColor = CinemaColors.neonRed;
              }

              return InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SeatMapScreen(showId: show['id']),
                  ));
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: CinemaColors.deepCharcoal,
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${show['format']} • ${show['language']}',
                        style: const TextStyle(
                          color: CinemaColors.steelGray,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
