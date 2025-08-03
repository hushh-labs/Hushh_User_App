import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

double topSpacing = 5.h;
double kChipHeight = 32;
double verticalPadding = 15;
double imageHeight = 30.w;
double basicInfoVerticalPadding = 10;
double actionButtonsVerticalPadding = 20;
double actionButtonHeight = 45;
double categoriesSpacing = 15;

class AgentProfileHeader extends StatelessWidget {
  final Map<String, dynamic> agent;

  const AgentProfileHeader({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      collapseMode: CollapseMode.parallax,
      background: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topSpacing),
              // Agent Profile Picture
              CircleAvatar(
                radius: imageHeight / 2,
                backgroundImage: NetworkImage(
                  agent['avatar'] ?? 'https://via.placeholder.com/100',
                ),
                backgroundColor: Colors.grey[300],
              ),
              Padding(
                padding: EdgeInsets.only(top: basicInfoVerticalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent['name'] ?? 'Agent Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1C140D),
                      ),
                    ),
                    Text(
                      "${agent['company'] ?? 'Company'}'s Agent",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xffC0C0C0),
                      ),
                    ),
                  ],
                ),
              ),
              if (agent['description']?.isNotEmpty ?? false)
                Padding(
                  padding: EdgeInsets.only(top: basicInfoVerticalPadding),
                  child: Text(
                    agent['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff171717),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              Text(
                "Categories",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: categoriesSpacing),
              Wrap(
                spacing: 8.0,
                children: [
                  Chip(
                    label: Text('Electronics'),
                    side: BorderSide.none,
                    backgroundColor: Colors.grey.shade400.withValues(
                      alpha: 0.7,
                    ),
                    labelStyle: const TextStyle(color: Colors.black),
                  ),
                  Chip(
                    label: Text('Fashion'),
                    side: BorderSide.none,
                    backgroundColor: Colors.grey.shade400.withValues(
                      alpha: 0.7,
                    ),
                    labelStyle: const TextStyle(color: Colors.black),
                  ),
                  Chip(
                    label: Text('Home'),
                    side: BorderSide.none,
                    backgroundColor: Colors.grey.shade400.withValues(
                      alpha: 0.7,
                    ),
                    labelStyle: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
