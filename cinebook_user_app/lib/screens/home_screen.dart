import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/movies');
      setState(() {
        _movies = res.data;
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
    return ListView.builder(
      itemCount: _movies.length,
      itemBuilder: (context, index) {
        final movie = _movies[index];
        return ListTile(
          leading: movie['posterUrl'] != null 
              ? Image.network(movie['posterUrl'], width: 50, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie, size: 50))
              : const Icon(Icons.movie, size: 50),
          title: Text(movie['title'] ?? 'Unknown'),
          subtitle: Text((movie['genres'] as List?)?.map((g) => g['name']).join(', ') ?? ''),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => MovieDetailScreen(movieId: movie['id']),
            ));
          },
        );
      },
    );
  }
}
