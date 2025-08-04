import 'package:flutter/material.dart';

class DiscoverSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isExpanded;
  final bool isVisible;
  final VoidCallback onToggle;
  final Function(String) onSearch;

  const DiscoverSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isExpanded,
    required this.isVisible,
    required this.onToggle,
    required this.onSearch,
  });

  @override
  State<DiscoverSearchBar> createState() => _DiscoverSearchBarState();
}

class _DiscoverSearchBarState extends State<DiscoverSearchBar> {
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color borderColor = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            decoration: const InputDecoration(
              hintText: 'Search for anything...',
              prefixIcon: Icon(Icons.search, color: primaryPurple),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: widget.onSearch,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onSearch(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Searching for: $value'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
