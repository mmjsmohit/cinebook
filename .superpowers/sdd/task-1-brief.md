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

