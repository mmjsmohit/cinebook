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
  List<dynamic> _similarMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.dio.get('/movies/${widget.movieId}'),
        api.dio.get('/movies/${widget.movieId}/reviews'),
        api.dio.get('/movies/${widget.movieId}/similar'),
      ]);
      setState(() {
        _movie = results[0].data['movie'];
        _reviews = results[1].data['reviews'];
        _similarMovies = results[2].data['movies'];
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
                const SizedBox(height: 24),
                if (_similarMovies.isNotEmpty) ...[
                  Text('Similar Movies', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _similarMovies.length,
                      itemBuilder: (context, index) {
                        final sm = _similarMovies[index];
                        return GestureDetector(
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movieId: sm['id']))),
                          child: Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: sm['posterUrl'] != null 
                                    ? Image.network(sm['posterUrl'], height: 120, width: 110, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 120, width: 110, color: CinemaColors.deepCharcoal))
                                    : Container(height: 120, width: 110, color: CinemaColors.deepCharcoal),
                                ),
                                const SizedBox(height: 4),
                                Text(sm['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }
}
