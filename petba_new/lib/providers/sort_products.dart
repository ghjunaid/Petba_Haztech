import 'package:flutter/material.dart';

class SortBottomSheet extends StatelessWidget {
  final String currentSortBy;
  final List<String> sortOptions;
  final Function(String) onSortChanged;

  const SortBottomSheet({
    Key? key,
    required this.currentSortBy,
    required this.sortOptions,
    required this.onSortChanged,
  }) : super(key: key);

  // Default sort options if none provided
  static const List<String> defaultSortOptions = [
    'Featured',
    'Price: Low to High',
    'Price: High to Low',
    'Rating',
    'Newest'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          const Text(
            'Sort By',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Sort Options
          ...sortOptions.map((option) {
            return _buildSortOption(context, option);
          }).toList(),

          // Add some bottom padding for better UX
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, String option) {
    final isSelected = option == currentSortBy;

    return InkWell(
      onTap: () {
        onSortChanged(option);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              option,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Static method to show the bottom sheet
  static void show({
    required BuildContext context,
    required String currentSortBy,
    required Function(String) onSortChanged,
    List<String>? sortOptions,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SortBottomSheet(
          currentSortBy: currentSortBy,
          sortOptions: sortOptions ?? defaultSortOptions,
          onSortChanged: onSortChanged,
        );
      },
    );
  }
}

// Helper widget for the sort trigger button
class SortButton extends StatelessWidget {
  final String currentSortBy;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const SortButton({
    Key? key,
    required this.currentSortBy,
    required this.onPressed,
    this.padding,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                currentSortBy,
                style: textStyle ?? TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


