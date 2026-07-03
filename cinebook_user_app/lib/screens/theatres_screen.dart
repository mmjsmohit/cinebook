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
  List<dynamic> _filteredTheatres = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTheatres();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterTheatres();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTheatres() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/theatres');
      if (!mounted) return;
      setState(() {
        _theatres = res.data['theatres'] ?? [];
        _filteredTheatres = List.from(_theatres);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: CinemaColors.neonRed));
    }
  }

  void _filterTheatres() {
    if (_searchQuery.isEmpty) {
      _filteredTheatres = List.from(_theatres);
    } else {
      _filteredTheatres = _theatres.where((t) {
        final name = (t['name'] ?? '').toString().toLowerCase();
        final city = (t['city'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || city.contains(_searchQuery);
      }).toList();
    }
  }

  Widget _getChainLogo(String name) {
    final lowerName = name.toLowerCase();
    String initial = name.isNotEmpty ? name[0] : 'T';
    Color bgColor = CinemaColors.structuralBorder;
    
    if (lowerName.contains('pvr')) {
      bgColor = Colors.amber.shade800;
      initial = 'PVR';
    } else if (lowerName.contains('inox')) {
      bgColor = Colors.blue.shade800;
      initial = 'INOX';
    } else if (lowerName.contains('cinepolis')) {
      bgColor = Colors.lightBlue.shade800;
      initial = 'C';
    } else if (lowerName.contains('imax')) {
      bgColor = Colors.deepPurple.shade800;
      initial = 'IMAX';
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CinemaColors.offWhite.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: CinemaColors.offWhite,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinemaColors.deepCharcoal,
      appBar: AppBar(
        title: const Text('Theatres', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: CinemaColors.offWhite),
              decoration: InputDecoration(
                hintText: 'Search theatres or cities...',
                hintStyle: const TextStyle(color: CinemaColors.steelGray),
                prefixIcon: const Icon(Icons.search, color: CinemaColors.steelGray),
                filled: true,
                fillColor: CinemaColors.inkCharcoal,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CinemaColors.structuralBorder),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CinemaColors.neonRed))
          : _filteredTheatres.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filteredTheatres.length,
                  itemBuilder: (context, index) {
                    final t = _filteredTheatres[index];
                    return _buildTheatreCard(t);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.theaters_outlined, size: 80, color: CinemaColors.steelGray.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No theatres found',
            style: TextStyle(color: CinemaColors.steelGray, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: TextStyle(color: CinemaColors.steelGray.withValues(alpha: 0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTheatreCard(dynamic t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CinemaColors.inkCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CinemaColors.structuralBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theatre shows coming soon!'), backgroundColor: CinemaColors.successGreen),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getChainLogo(t['name'] ?? ''),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['name'] ?? 'Unknown Theatre',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: CinemaColors.offWhite,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 14, color: CinemaColors.steelGray),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${t['location'] ?? ''}, ${t['city'] ?? ''}',
                                  style: const TextStyle(
                                    color: CinemaColors.steelGray,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: CinemaColors.structuralBorder),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildFeatureTag(Icons.fastfood, 'Food & Bev'),
                        const SizedBox(width: 8),
                        _buildFeatureTag(Icons.accessible, 'Accessible'),
                      ],
                    ),
                    Row(
                      children: const [
                        Text('View Shows', style: TextStyle(color: CinemaColors.warmAmber, fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: CinemaColors.warmAmber),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CinemaColors.deepCharcoal,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CinemaColors.structuralBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: CinemaColors.steelGray),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: CinemaColors.steelGray, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
