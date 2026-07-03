import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieSearchField extends StatefulWidget {
  final String? initialMovieId;
  final String? initialMovieTitle;
  final ValueChanged<Map<String, dynamic>> onMovieSelected;

  const MovieSearchField({
    super.key,
    this.initialMovieId,
    this.initialMovieTitle,
    required this.onMovieSelected,
  });

  @override
  State<MovieSearchField> createState() => _MovieSearchFieldState();
}

class _MovieSearchFieldState extends State<MovieSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedMovie;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMovieTitle != null) {
      _controller.text = widget.initialMovieTitle!;
      _selectedMovie = {'id': widget.initialMovieId, 'title': widget.initialMovieTitle};
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showResults = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _selectedMovie = null);
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/movies', queryParameters: {'q': query});
      setState(() {
        _results = res.data['movies'] ?? [];
        _showResults = true;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Search Movie',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _selectedMovie != null
                    ? const Icon(Icons.check_circle, color: CinemaColors.successGreen)
                    : null,
          ),
          onChanged: _onSearchChanged,
        ),
        if (_showResults && _results.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: CinemaColors.inkCharcoal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CinemaColors.structuralBorder),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final movie = _results[index];
                return ListTile(
                  dense: true,
                  title: Text(movie['title'] ?? '', style: theme.textTheme.bodyLarge),
                  subtitle: Text('${movie['runtimeMin'] ?? '?'} min', style: theme.textTheme.bodySmall),
                  onTap: () {
                    setState(() {
                      _selectedMovie = movie;
                      _controller.text = movie['title'];
                      _showResults = false;
                    });
                    _focusNode.unfocus();
                    widget.onMovieSelected(movie);
                  },
                );
              },
            ),
          ),
        if (_showResults && _results.isEmpty && !_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('No movies found', style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}
