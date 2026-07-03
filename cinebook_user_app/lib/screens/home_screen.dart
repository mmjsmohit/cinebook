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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('CineBook', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (_trendingMovies.isNotEmpty) 
              FeaturedMovieCarousel(movies: _trendingMovies),
            
            const SizedBox(height: 24),
            
            CategoryListWidget(
              title: 'Browse by Genre',
              items: _genres,
              onSelect: (g) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${g['name']}'))),
            ),
            
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Releases', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('See All')),
                ],
              ),
            ),
            
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _upcomingMovies.length,
                itemBuilder: (context, index) {
                  final movie = _upcomingMovies[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movieId: movie['id'])));
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: movie['posterUrl'] != null 
                                  ? Image.network(
                                      movie['posterUrl'], 
                                      fit: BoxFit.cover, 
                                      width: double.infinity,
                                      errorBuilder: (ctx, err, st) => Container(color: CinemaColors.inkCharcoal, child: const Icon(Icons.movie, color: CinemaColors.steelGray)),
                                    )
                                  : Container(color: CinemaColors.inkCharcoal, child: const Icon(Icons.movie, color: CinemaColors.steelGray)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            movie['title'] ?? 'Unknown', 
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (movie['genres'] as List?)?.map((g) => g['name']).join(', ') ?? '', 
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: CinemaColors.steelGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            CategoryListWidget(
              title: 'Languages',
              items: _languages,
              onSelect: (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${l['name']}'))),
            ),
          ],
        ),
      ),
    );
  }
}
