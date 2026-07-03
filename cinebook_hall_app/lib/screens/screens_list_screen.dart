import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import '../widgets/screen_card.dart';
import 'show_calendar_screen.dart';

class ScreensListScreen extends StatefulWidget {
  const ScreensListScreen({super.key});
  @override
  State<ScreensListScreen> createState() => _ScreensListScreenState();
}

class _ScreensListScreenState extends State<ScreensListScreen> {
  List<dynamic> _screens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScreens();
  }

  Future<void> _fetchScreens() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/me/screens');
      setState(() {
        _screens = res.data['screens'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Map<String, List<dynamic>> _groupByTheatre() {
    final grouped = <String, List<dynamic>>{};
    for (final screen in _screens) {
      final theatreName = screen['theatre']?['name'] ?? 'Unknown Theatre';
      grouped.putIfAbsent(theatreName, () => []).add(screen);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Screens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(AuthLoggedOut()),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.tv_off, size: 64, color: CinemaColors.steelGray),
                      const SizedBox(height: 16),
                      Text('No screens assigned', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Contact admin to get screens assigned to you.', style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchScreens,
                  color: CinemaColors.neonRed,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    children: [
                      for (final entry in _groupByTheatre().entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: CinemaColors.steelGray),
                              const SizedBox(width: 6),
                              Text(
                                entry.key,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.2,
                                  color: CinemaColors.steelGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final screen in entry.value)
                          ScreenCard(
                            screen: screen,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShowCalendarScreen(
                                  screenId: screen['id'],
                                  screenName: screen['name'],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
