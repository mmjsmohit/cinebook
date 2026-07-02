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
