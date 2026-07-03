import 'package:flutter/material.dart';
import 'package:cinebook_core/cinebook_core.dart';

class DateHeader extends StatelessWidget {
  final String dateLabel;
  const DateHeader({super.key, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CinemaColors.neonRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: CinemaColors.neonRed,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: CinemaColors.structuralBorder),
          ),
        ],
      ),
    );
  }
}
