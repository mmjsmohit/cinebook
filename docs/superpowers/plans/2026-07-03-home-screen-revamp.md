# Movie Browse & Details Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completely revamp the Home screen to a SeatGeek-inspired dashboard that consumes the trending, upcoming, genres, and languages APIs, and add similar movies to the Movie Details screen.

**Architecture:** We will create reusable widgets (`FeaturedMovieCard`, `CategoryListWidget`) to build out the home dashboard, and update the existing stateful screens (`home_screen.dart`, `movie_detail_screen.dart`) to execute the new parallel API calls using `Future.wait`.

**Tech Stack:** Flutter, Dio (via existing ApiClient)

## Global Constraints

- All colors must come from `CinemaColors` or `Theme.of(context)`. Zero raw `Colors.*` or `Color(0xFF...)` in screen files.
- Typography must use `Theme.of(context).textTheme.*` everywhere.
- Run `flutter analyze` after every task to verify zero analysis errors.

---

### Task 1: Create SeatGeek-inspired Reusable Widgets

**Files:**
- Create: `/Users/mohittiwari/Dev/Cinebook/cinebook_user_app/lib/widgets/featured_movie_card.dart`
- Create: `/Users/mohittiwari/Dev/Cinebook/cinebook_user_app/lib/widgets/category_list_widget.dart`

**Interfaces:**
- Produces: `FeaturedMovieCard(movie: Map<String, dynamic>)`
- Produces: `CategoryListWidget(title: String, items: List<dynamic>, onSelect: (item) {})`

- [ ] **Step 1: Write `featured_movie_card.dart`**
Create a large, visually striking card (similar to the Lakers at Warriors ref).

```dart
import 'package:flutter/material.dart';
import 'package:cinebook_core/cinebook_core.dart';
import '../screens/movie_detail_screen.dart';

class FeaturedMovieCard extends StatelessWidget {
  final Map<String, dynamic> movie;
  const FeaturedMovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MovieDetailScreen(movieId: movie['id']),
        ));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(movie['posterUrl'] ?? 'https://via.placeholder.com/400'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
          ),
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
                child: Text('FEATURED', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(movie['title'] ?? 'Unknown', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text((movie['genres'] as List?)?.map((g) => g['name']).join(', ') ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write `category_list_widget.dart`**
Create a horizontal scrolling list for categories (genres/languages).

```dart
import 'package:flutter/material.dart';
import 'package:cinebook_core/cinebook_core.dart';

class CategoryListWidget extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final Function(dynamic) onSelect;

  const CategoryListWidget({super.key, required this.title, required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => onSelect(item),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(12),
                  child: Text(item['name'] ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Verify static analysis**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Commit**
```bash
git add cinebook_user_app/lib/widgets/
git commit -m "feat: add FeaturedMovieCard and CategoryListWidget components"
```

---

### Task 2: Refactor Home Screen to Consume New APIs

**Files:**
- Modify: `/Users/mohittiwari/Dev/Cinebook/cinebook_user_app/lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `FeaturedMovieCard`, `CategoryListWidget`

- [ ] **Step 1: Update API calls in `home_screen.dart`**
Replace the single `/movies` call with parallel calls for trending, upcoming, genres, and languages. Also import the new widgets.

```dart
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
            onSelect: (g) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${g['name']}')),
          ),
          const SizedBox(height: 16),
          CategoryListWidget(
            title: 'Languages',
            items: _languages,
            onSelect: (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${l['name']}')),
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
```

- [ ] **Step 2: Verify static analysis**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 3: Commit**
```bash
git add cinebook_user_app/lib/screens/home_screen.dart
git commit -m "feat: revamp home screen with trending, upcoming, genres, and languages"
```

---

### Task 3: Add Similar Movies to Movie Detail Screen

**Files:**
- Modify: `/Users/mohittiwari/Dev/Cinebook/cinebook_user_app/lib/screens/movie_detail_screen.dart`

**Interfaces:**
- Consumes: `/movies/:id/similar` API

- [ ] **Step 1: Update API calls in `movie_detail_screen.dart`**
Add the similar movies fetch and display them at the bottom.

In `_MovieDetailScreenState`, add `List<dynamic> _similarMovies = [];` and update `_fetchDetails()`:
```dart
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
```

- [ ] **Step 2: Update `build` method in `movie_detail_screen.dart`**
Append a horizontally scrolling list of similar movies at the end of the `Column` inside the `SingleChildScrollView`.

```dart
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
                                    ? Image.network(sm['posterUrl'], height: 120, width: 110, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(height: 120, width: 110, color: CinemaColors.charcoalBackground))
                                    : Container(height: 120, width: 110, color: CinemaColors.charcoalBackground),
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
```

- [ ] **Step 3: Verify static analysis**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Commit**
```bash
git add cinebook_user_app/lib/screens/movie_detail_screen.dart
git commit -m "feat: display similar movies in movie detail screen"
```
