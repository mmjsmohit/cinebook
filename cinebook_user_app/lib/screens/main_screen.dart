import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'home_screen.dart';
import 'theatres_screen.dart';
import 'history_screen.dart';
import 'agent_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final _pages = [
    const HomeScreen(),
    const TheatresScreen(),
    const AgentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 || _currentIndex == 1
          ? AppBar(
              title: Text(_currentIndex == 0 ? 'CineBook' : 'Theatres'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () =>
                      context.read<AuthBloc>().add(AuthLoggedOut()),
                ),
              ],
            )
          : null,
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.movie), label: 'Movies'),
          NavigationDestination(icon: Icon(Icons.theaters), label: 'Theatres'),
          NavigationDestination(icon: Icon(Icons.smart_toy), label: 'Assistant'),
        ],
      ),
    );
  }
}
