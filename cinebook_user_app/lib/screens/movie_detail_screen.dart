import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'showtimes_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Map<String, dynamic>? _movie;
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/movies/${widget.movieId}');
      final revRes = await api.dio.get('/movies/${widget.movieId}/reviews');
      setState(() {
        _movie = res.data['movie'];
        _reviews = revRes.data['reviews'];
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
      appBar: AppBar(title: Text(_movie?['title'] ?? 'Details')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_movie?['posterUrl'] != null)
                  Image.network(_movie!['posterUrl'], height: 300, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie, color: CinemaColors.steelGray)),
                const SizedBox(height: 16),
                Text(_movie?['title'] ?? '', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(_movie?['description'] ?? ''),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShowtimesScreen(movieId: widget.movieId))),
                  child: const Text('View Showtimes'),
                ),
                const SizedBox(height: 24),
                Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
                ..._reviews.map((r) => ListTile(
                  title: Text(r['author'] ?? ''),
                  subtitle: Text(r['body'] ?? ''),
                  trailing: Text('${r['rating']} ★'),
                )),
              ],
            ),
          ),
    );
  }
}
