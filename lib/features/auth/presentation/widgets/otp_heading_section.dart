import 'package:flutter/material.dart';

class OtpHeadingSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emailOrPhone;

  const OtpHeadingSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emailOrPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.7),
                height: 1.5,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: emailOrPhone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
