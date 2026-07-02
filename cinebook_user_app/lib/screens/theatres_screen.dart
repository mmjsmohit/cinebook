import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';

class TheatresScreen extends StatefulWidget {
  const TheatresScreen({super.key});

  @override
  State<TheatresScreen> createState() => _TheatresScreenState();
}

class _TheatresScreenState extends State<TheatresScreen> {
  List<dynamic> _theatres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTheatres();
  }

  Future<void> _fetchTheatres() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/theatres');
      setState(() {
        _theatres = res.data['theatres'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theatres')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _theatres.isEmpty
              ? Center(child: Text('No theatres available.', style: Theme.of(context).textTheme.bodyLarge))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _theatres.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = _theatres[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(t['name'] ?? 'Unknown', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          t['location'] ?? 'Location unavailable',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.steelGray),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary, size: 16),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Theatre shows coming soon!')),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
