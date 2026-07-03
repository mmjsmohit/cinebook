import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:intl/intl.dart';
import '../widgets/show_card.dart';
import '../widgets/date_header.dart';
import 'show_form_screen.dart';

class ShowCalendarScreen extends StatefulWidget {
  final String screenId;
  final String screenName;
  const ShowCalendarScreen({super.key, required this.screenId, required this.screenName});

  @override
  State<ShowCalendarScreen> createState() => _ShowCalendarScreenState();
}

class _ShowCalendarScreenState extends State<ShowCalendarScreen> {
  List<dynamic> _shows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShows();
  }

  Future<void> _fetchShows() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/screens/${widget.screenId}/shows');
      setState(() {
        _shows = res.data['shows'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> show) async {
    final api = context.read<ApiClient>();
    final movieTitle = show['movie']?['title'] ?? 'this show';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Show'),
        content: Text('Are you sure you want to delete the show for "$movieTitle"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CinemaColors.neonRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await api.dio.delete('/shows/${show['id']}');
        _fetchShows();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Map<String, List<dynamic>> _groupByDate() {
    final grouped = <String, List<dynamic>>{};
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    for (final show in _shows) {
      final dt = DateTime.parse(show['startTime']);
      final key = dateFormat.format(dt);
      grouped.putIfAbsent(key, () => []).add(show);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.screenName)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CinemaColors.neonRed,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => ShowFormScreen(screenId: widget.screenId),
          ));
          if (mounted) _fetchShows();
        },
        child: const Icon(Icons.add, color: CinemaColors.offWhite),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy, size: 64, color: CinemaColors.steelGray),
                      const SizedBox(height: 16),
                      Text('No shows scheduled', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Tap + to add a show', style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchShows,
                  color: CinemaColors.neonRed,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      for (final entry in _groupByDate().entries) ...[
                        DateHeader(dateLabel: entry.key),
                        for (final show in entry.value)
                          ShowCard(
                            show: show,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ShowFormScreen(screenId: widget.screenId, showData: show),
                              ));
                              if (mounted) _fetchShows();
                            },
                            onDelete: () => _confirmDelete(show),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
