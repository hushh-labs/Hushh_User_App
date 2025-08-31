import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/agent_model.dart';

/// Card used in the Discover page to display an Agent in a 2-column grid
class AgentCard extends StatelessWidget {
  final AgentModel agent;
  final String? coverImageUrl;
  final VoidCallback onTap;
  final String? subtitleText;
  final String? infoText;

  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);

  const AgentCard({
    super.key,
    required this.agent,
    required this.onTap,
    this.coverImageUrl,
    this.subtitleText,
    this.infoText,
  });

  // No additional summary line; keep the card clean

  @override
  Widget build(BuildContext context) {
    const double radius = 16;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top image area with overlays
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    // Taller header area for the avatar
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF9F6), // Warm off-white color
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/avtar_agent.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to initials if image fails to load
                                  return Text(
                                    _getInitials(agent.name),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AGENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details (fills remaining height, prevents overflow)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10), // Reduced from 12 to 10
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                  children: [
                    Text(
                      agent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18, // Reduced from 20 to 18
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 1), // Reduced from 2 to 1
                    if ((subtitleText ?? agent.brandName).trim().isNotEmpty)
                      Text(
                        (subtitleText ?? agent.brandName).trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14, // Reduced from 16 to 14
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if ((infoText ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 2,
                        ), // Reduced from 4 to 2
                        child: Text(
                          (infoText ?? '').trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12, // Reduced from 13 to 12
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, // Reduced from 10 to 8
                            vertical: 4, // Reduced from 6 to 4
                          ),
                          decoration: BoxDecoration(
                            // Off-black background for the forward arrow button
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Reduced from 12 to 10
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 16, // Reduced from 18 to 16
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final List<String> words = name.split(' ');
    if (words.length > 1) {
      return '${words[0][0]}${words[1][0]}';
    } else if (words.isNotEmpty) {
      return words[0][0];
    }
    return '';
  }
}
