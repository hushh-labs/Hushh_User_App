import 'package:flutter/material.dart';

class ConciergeAgentCard extends StatelessWidget {
  final String name;
  final String location;
  final String services;
  final double rating;
  final String imageUrl;
  final String? brand;
  final String? industry;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const ConciergeAgentCard({
    super.key,
    required this.name,
    required this.location,
    required this.services,
    required this.rating,
    required this.imageUrl,
    this.brand,
    this.industry,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image tile
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.4, // reduce image height slightly
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 2),
          // Brand (fallback to location)
          Text(
            brand == null || brand!.isEmpty ? location : brand!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6E73),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          // Industry (fallback to services)
          Text(
            industry == null || industry!.isEmpty ? services : industry!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6E73),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Grid widget for displaying multiple agent cards
class ConciergeAgentsGrid extends StatelessWidget {
  final List<ConciergeAgentData> agents;
  final Function(ConciergeAgentData)? onAgentTap;
  final Function(ConciergeAgentData)? onFavoriteTap;

  const ConciergeAgentsGrid({
    super.key,
    required this.agents,
    this.onAgentTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9, // a bit taller to avoid bottom overflow
        ),
        itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          return ConciergeAgentCard(
            name: agent.name,
            location: agent.location,
            services: agent.services,
            brand: agent.brand,
            industry: agent.industry,
            rating: agent.rating,
            imageUrl: agent.imageUrl,
            isFavorite: agent.isFavorite,
            onTap: () => onAgentTap?.call(agent),
            onFavoriteTap: () => onFavoriteTap?.call(agent),
          );
        },
      ),
    );
  }
}

// Data model for agent information
class ConciergeAgentData {
  final String name;
  final String location;
  final String services;
  final double rating;
  final String imageUrl;
  final bool isFavorite;
  final String? brand;
  final String? industry;

  ConciergeAgentData({
    required this.name,
    required this.location,
    required this.services,
    required this.rating,
    required this.imageUrl,
    this.isFavorite = false,
    this.brand,
    this.industry,
  });
}
