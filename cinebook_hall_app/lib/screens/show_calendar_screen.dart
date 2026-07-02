import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'show_form_screen.dart';

class ShowCalendarScreen extends StatefulWidget {
  final String screenId;
  final String screenName;

  const ShowCalendarScreen({super.key, required this.screenId, required this.screenName});

  @override
  State<ShowCalendarScreen> createState() => _ShowCalendarScreenState();
}

class _ShowCalendarScreenState extends State<ShowCalendarScreen> {
  List<dynamic> _shows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShows();
  }

  Future<void> _fetchShows() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/screens/${widget.screenId}/shows'); 
      setState(() {
        _shows = res.data['shows'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteShow(String showId) async {
    try {
      final api = context.read<ApiClient>();
      await api.dio.delete('/shows/$showId');
      _fetchShows();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.screenName} Shows'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => ShowFormScreen(screenId: widget.screenId),
              ));
              _fetchShows(); 
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _shows.length,
              itemBuilder: (context, index) {
                final show = _shows[index];
                return ListTile(
                  title: Text(show['movie']?['title'] ?? 'Unknown Movie'),
                  subtitle: Text('${show['startTime']} - ${show['language']} ${show['format']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteShow(show['id']),
                  ),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ShowFormScreen(screenId: widget.screenId, showData: show),
                    ));
                    _fetchShows();
                  },
                );
              },
            ),
    );
  }
}
