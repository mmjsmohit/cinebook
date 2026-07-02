import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchShows();
  }

  Future<void> _fetchShows() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/shows?movieId=${widget.movieId}');
      setState(() {
        _shows = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Showtimes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _shows.length,
              itemBuilder: (context, index) {
                final show = _shows[index];
                return ListTile(
                  title: Text(show['screen']?['name'] ?? 'Screen'),
                  subtitle: Text('${show['startTime']} - ${show['language']} ${show['format']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SeatMapScreen(showId: show['id']),
                    ));
                  },
                );
              },
            ),
    );
  }
}
