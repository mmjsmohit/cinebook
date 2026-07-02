import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import '../widgets/featured_movie_card.dart';
import '../widgets/category_list_widget.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _trendingMovies = [];
  List<dynamic> _upcomingMovies = [];
  List<dynamic> _genres = [];
  List<dynamic> _languages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.dio.get('/movies/trending'),
        api.dio.get('/movies/upcoming?date=${DateTime.now().toIso8601String().split('T')[0]}'),
        api.dio.get('/genres'),
        api.dio.get('/languages'),
      ]);
      setState(() {
        _trendingMovies = results[0].data['movies'];
        _upcomingMovies = results[1].data['movies'];
        _genres = results[2].data['genres'];
        _languages = results[3].data['languages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (_trendingMovies.isNotEmpty) FeaturedMovieCard(movie: _trendingMovies.first),
          const SizedBox(height: 16),
          CategoryListWidget(
            title: 'Browse by Genre',
            items: _genres,
            onSelect: (g) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${g['name']}'))),
          ),
          const SizedBox(height: 16),
          CategoryListWidget(
            title: 'Languages',
            items: _languages,
            onSelect: (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${l['name']}'))),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Upcoming Releases', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ..._upcomingMovies.map((movie) => ListTile(
            leading: movie['posterUrl'] != null 
                ? Image.network(movie['posterUrl'], width: 50, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie, size: 50, color: CinemaColors.steelGray))
                : const Icon(Icons.movie, size: 50, color: CinemaColors.steelGray),
            title: Text(movie['title'] ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text((movie['genres'] as List?)?.map((g) => g['name']).join(', ') ?? ''),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movieId: movie['id'])));
            },
          )),
        ],
      ),
    );
  }
}
