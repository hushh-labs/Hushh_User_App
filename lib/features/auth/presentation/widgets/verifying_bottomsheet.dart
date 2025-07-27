import 'package:flutter/material.dart';

class VerifyingBottomSheet extends StatelessWidget {
  final String title;
  final String message;

  const VerifyingBottomSheet({
    super.key,
    this.title = 'Verifying...',
    this.message =
        'We are processing your request, please do not close this screen...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4C4C4C), fontSize: 14),
            ),
          ),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0XFFA342FF),
                strokeWidth: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
