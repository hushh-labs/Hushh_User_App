import 'package:flutter/material.dart';

class IconGrid extends StatelessWidget {
  final List<GridItem> items;
  final int crossAxisCount;
  final double spacing;
  final bool useModernStyle;

  const IconGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 4,
    this.spacing = 12,
    this.useModernStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: useModernStyle ? 0.95 : 0.9,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return useModernStyle
              ? _buildModernItem(item)
              : _buildClassicItem(item);
        },
      ),
    );
  }

  Widget _buildModernItem(GridItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      item.gradientColors ??
                      [const Color(0xFFE8F4FD), const Color(0xFFD6EEF7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: item.icon != null
                  ? Icon(
                      item.icon,
                      color: item.iconColor ?? const Color(0xFF2B5CE6),
                      size: 24,
                    )
                  : (item.iconWidget ?? const SizedBox.shrink()),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicItem(GridItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              border: Border.all(color: const Color(0xFFE6E6EC)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: item.icon != null
                ? Icon(item.icon, color: const Color(0xFF616180))
                : (item.iconWidget ?? const SizedBox.shrink()),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF616180),
            ),
          ),
        ],
      ),
    );
  }
}

class GridItem {
  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final Color? iconColor;

  GridItem({
    required this.label,
    this.icon,
    this.iconWidget,
    this.onTap,
    this.gradientColors,
    this.iconColor,
  });
}
