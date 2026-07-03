import 'package:flutter/material.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:intl/intl.dart';

class ShowCard extends StatelessWidget {
  final Map<String, dynamic> show;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ShowCard({super.key, required this.show, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = DateTime.parse(show['startTime']);
    final endTime = DateTime.parse(show['endTime']);
    final timeFormat = DateFormat('h:mm a');
    final movieTitle = show['movie']?['title'] ?? 'Unknown Movie';
    final runtime = show['movie']?['runtimeMin'];
    final language = show['language'] ?? '';
    final format = show['format'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timeFormat.format(startTime), style: theme.textTheme.titleMedium),
                      Text(
                        '→ ${timeFormat.format(endTime)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Movie info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movieTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        if (runtime != null)
                          Text('$runtime min', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  // Edit indicator
                  const Icon(Icons.edit_outlined, size: 18, color: CinemaColors.steelGray),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(language, CinemaColors.warmAmber),
                  const SizedBox(width: 8),
                  _buildChip(format, CinemaColors.successGreen),
                  const Spacer(),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: CinemaColors.neonRed,
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
