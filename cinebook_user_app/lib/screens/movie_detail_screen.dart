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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.white)), backgroundColor: CinemaColors.neonRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: CinemaColors.neonRed)),
      );
    }

    if (_movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Movie not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleAndMeta(),
                  const SizedBox(height: 24),
                  _buildSynopsis(),
                  const SizedBox(height: 24),
                  if ((_movie!['cast'] as List?)?.isNotEmpty ?? false)
                    _buildCast(),
                  const SizedBox(height: 24),
                  if (_similarMovies.isNotEmpty) _buildSimilarMovies(),
                  const SizedBox(height: 24),
                  if (_reviews.isNotEmpty) _buildReviews(),
                  const SizedBox(height: 80), // Padding for sticky button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActionBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: CinemaColors.inkCharcoal,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_movie!['posterUrl'] != null)
              Image.network(
                _movie!['posterUrl'],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: CinemaColors.deepCharcoal),
              )
            else
              Container(color: CinemaColors.deepCharcoal),
            
            // Gradient overlay for text readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    CinemaColors.deepCharcoal,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: CinemaColors.offWhite),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTitleAndMeta() {
    final genres = _movie!['genres'] as List? ?? [];
    final languages = _movie!['languages'] as List? ?? [];
    final runtime = _movie!['runtimeMin'] as int? ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _movie!['title'] ?? '',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: CinemaColors.offWhite,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_movie!['ageRating'] != null)
              _buildBadge(_movie!['ageRating'], color: CinemaColors.warmAmber),
            if (runtime > 0)
              _buildBadge('${runtime ~/ 60}h ${runtime % 60}m', icon: Icons.schedule),
            if (languages.isNotEmpty)
              _buildBadge(languages.first.toString(), icon: Icons.language),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.map((g) {
            return Chip(
              label: Text(g['name'] ?? '', style: const TextStyle(fontSize: 12)),
              backgroundColor: CinemaColors.structuralBorder.withValues(alpha: 0.5),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, {IconData? icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? CinemaColors.steelGray).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (color ?? CinemaColors.steelGray).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? CinemaColors.steelGray),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? CinemaColors.offWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSynopsis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _movie!['description'] ?? 'No description available.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CinemaColors.steelGray,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildCast() {
    final cast = _movie!['cast'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cast',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final actor = cast[index].toString();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: CinemaColors.structuralBorder,
                      child: Text(
                        actor.isNotEmpty ? actor[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 20, color: CinemaColors.steelGray),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        actor,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: CinemaColors.warmAmber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_calculateAverageRating().toStringAsFixed(1)} / 5.0',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._reviews.take(3).map((r) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CinemaColors.inkCharcoal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CinemaColors.structuralBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r['author'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (r['rating'] as num? ?? 0) ? Icons.star : Icons.star_border,
                        size: 14,
                        color: CinemaColors.warmAmber,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                r['body'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.steelGray),
              ),
            ],
          ),
        )),
      ],
    );
  }

  double _calculateAverageRating() {
    if (_reviews.isEmpty) return 0;
    double total = 0;
    for (final r in _reviews) {
      total += (r['rating'] as num? ?? 0).toDouble();
    }
    return total / _reviews.length;
  }

  Widget _buildSimilarMovies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Similar Movies', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _similarMovies.length,
            itemBuilder: (context, index) {
              final sm = _similarMovies[index];
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movieId: sm['id']))),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: sm['posterUrl'] != null 
                          ? Image.network(sm['posterUrl'], height: 140, width: 120, fit: BoxFit.cover, errorBuilder: (_,_,_) => _fallbackPoster())
                          : _fallbackPoster(),
                      ),
                      const SizedBox(height: 8),
                      Text(sm['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fallbackPoster() {
    return Container(
      height: 140,
      width: 120,
      color: CinemaColors.inkCharcoal,
      child: const Center(child: Icon(Icons.movie, color: CinemaColors.steelGray)),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CinemaColors.deepCharcoal.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: CinemaColors.structuralBorder)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ShowtimesScreen(movieId: widget.movieId)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CinemaColors.neonRed,
              foregroundColor: CinemaColors.offWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text(
              'View Showtimes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
