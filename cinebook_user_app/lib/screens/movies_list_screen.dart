import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:intl/intl.dart';
import 'movie_detail_screen.dart';

class MoviesListScreen extends StatefulWidget {
  final String filterType; // 'genre', 'language', 'search', 'upcoming'
  final String? filterValue;

  const MoviesListScreen({
    super.key,
    required this.filterType,
    this.filterValue,
  });

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen> {
  bool _isLoading = true;
  List<dynamic> _movies = [];
  String? _error;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.filterType == 'search' && widget.filterValue != null) {
      _searchController.text = widget.filterValue!;
    }
    _fetchMovies();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      String endpoint = '/movies';
      
      if (widget.filterType == 'genre') {
        endpoint = '/movies?genre=${Uri.encodeComponent(widget.filterValue!)}';
      } else if (widget.filterType == 'language') {
        endpoint = '/movies?language=${Uri.encodeComponent(widget.filterValue!)}';
      } else if (widget.filterType == 'search') {
        final query = _searchController.text.trim();
        if (query.isNotEmpty) {
          endpoint = '/movies?q=${Uri.encodeComponent(query)}';
        }
      } else if (widget.filterType == 'upcoming') {
        endpoint = '/movies/upcoming';
      }

      final res = await api.dio.get(endpoint);
      if (mounted) {
        setState(() {
          _movies = res.data['movies'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load movies';
          _isLoading = false;
        });
      }
    }
  }
  
  void _performSearch() {
    if (widget.filterType == 'search') {
      _fetchMovies();
    }
  }

  String get _title {
    switch (widget.filterType) {
      case 'genre':
        return '${widget.filterValue} Movies';
      case 'language':
        return '${widget.filterValue} Movies';
      case 'search':
        return 'Search Movies';
      case 'upcoming':
        return 'Upcoming Releases';
      default:
        return 'Movies';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinemaColors.deepCharcoal,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (widget.filterType == 'search')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: CinemaColors.offWhite),
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'Search for movies...',
                  hintStyle: const TextStyle(color: CinemaColors.steelGray),
                  filled: true,
                  fillColor: CinemaColors.inkCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: CinemaColors.steelGray),
                    onPressed: _performSearch,
                  ),
                ),
              ),
            ),
            
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: CinemaColors.neonRed));
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: CinemaColors.neonRed)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMovies,
              style: ElevatedButton.styleFrom(backgroundColor: CinemaColors.neonRed),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_movies.isEmpty) {
      return const Center(
        child: Text(
          'No movies found.',
          style: TextStyle(color: CinemaColors.steelGray, fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _movies.length,
      itemBuilder: (context, index) {
        final movie = _movies[index];
        return _buildMovieCard(movie);
      },
    );
  }
  
  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MovieDetailScreen(movieId: movie['id']),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: CinemaColors.inkCharcoal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: movie['posterUrl'] != null
                  ? Image.network(
                      movie['posterUrl'],
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => const SizedBox(width: 100, height: 150, child: ColoredBox(color: CinemaColors.deepCharcoal)),
                    )
                  : const SizedBox(width: 100, height: 150, child: ColoredBox(color: CinemaColors.deepCharcoal)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie['title'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CinemaColors.offWhite,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (movie['genres'] != null)
                      Text(
                        (movie['genres'] as List).map((g) => g['name']).join(', '),
                        style: const TextStyle(color: CinemaColors.steelGray, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (movie['languages'] != null)
                      Text(
                        (movie['languages'] as List).join(', '),
                        style: const TextStyle(color: CinemaColors.steelGray, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    if (movie['ageRating'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CinemaColors.warmAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: CinemaColors.warmAmber.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          movie['ageRating'],
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CinemaColors.warmAmber),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
