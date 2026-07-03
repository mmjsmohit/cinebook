import 'package:flutter/material.dart';
import 'package:cinebook_core/cinebook_core.dart';
import '../screens/movie_detail_screen.dart';

class FeaturedMovieCarousel extends StatefulWidget {
  final List<dynamic> movies;
  const FeaturedMovieCarousel({super.key, required this.movies});

  @override
  State<FeaturedMovieCarousel> createState() => _FeaturedMovieCarouselState();
}

class _FeaturedMovieCarouselState extends State<FeaturedMovieCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.movies.length,
            itemBuilder: (context, index) {
              final movie = widget.movies[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 240,
                      width: Curves.easeOut.transform(value) * 350,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(movieId: movie['id']),
                    ));
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(movie['posterUrl'] ?? 'https://via.placeholder.com/400'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(CinemaColors.deepCharcoal.withValues(alpha: 0.4), BlendMode.darken),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: CinemaColors.neonRed, borderRadius: BorderRadius.circular(4)),
                            child: Text('FEATURED', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: CinemaColors.offWhite, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Text(movie['title'] ?? 'Unknown', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: CinemaColors.offWhite, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text((movie['genres'] as List?)?.map((g) => g['name']).join(', ') ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.steelGray)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.movies.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? CinemaColors.neonRed : CinemaColors.steelGray.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
