import 'package:flutter/material.dart';
import 'package:cinebook_core/cinebook_core.dart';

class ScreenCard extends StatelessWidget {
  final Map<String, dynamic> screen;
  final VoidCallback onTap;

  const ScreenCard({super.key, required this.screen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenType = screen['type']?.toString() ?? 'STANDARD';
    final format = screen['format']?.toString() ?? '';
    final seatCount = (screen['_count']?['seats'] ?? screen['seats']?.length) ?? 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Screen icon with tinted background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CinemaColors.neonRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tv, color: CinemaColors.neonRed),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(screen['name'] ?? 'Screen', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      screen['theatre']?['name'] ?? '',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChip(screenType, CinemaColors.warmAmber),
                        if (format.isNotEmpty) _buildChip(format, CinemaColors.steelGray),
                        _buildChip('$seatCount seats', CinemaColors.successGreen),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: CinemaColors.steelGray),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
