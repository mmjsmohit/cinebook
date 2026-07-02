import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
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
        _screens = res.data;
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
          : ListView.builder(
              itemCount: _screens.length,
              itemBuilder: (context, index) {
                final screen = _screens[index];
                return ListTile(
                  title: Text(screen['name']),
                  subtitle: Text('Capacity: ${screen['capacity']} | Format: ${(screen['supportedFormats'] as List?)?.join(', ') ?? ''}'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ShowCalendarScreen(screenId: screen['id'], screenName: screen['name']),
                    ));
                  },
                );
              },
            ),
    );
  }
}
