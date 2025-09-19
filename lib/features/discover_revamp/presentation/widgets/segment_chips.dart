import 'package:flutter/material.dart';

class SegmentChips extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  const SegmentChips({super.key, this.selectedIndex = 0, this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, {required bool selected, required int index}) {
      return GestureDetector(
        onTap: () => onChanged?.call(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.black : const Color(0xFFF0F0F3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF9A9AA6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          pill('Most Viewed', selected: selectedIndex == 0, index: 0),
          const SizedBox(width: 12),
          pill('Nearby', selected: selectedIndex == 1, index: 1),
          const SizedBox(width: 12),
          pill('Latest', selected: selectedIndex == 2, index: 2),
        ],
      ),
    );
  }
}
