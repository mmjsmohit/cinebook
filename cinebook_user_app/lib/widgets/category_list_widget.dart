import 'package:flutter/material.dart';


class CategoryListWidget extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final Function(dynamic) onSelect;

  const CategoryListWidget({super.key, required this.title, required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => onSelect(item),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(12),
                  child: Text(item['name'] ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
