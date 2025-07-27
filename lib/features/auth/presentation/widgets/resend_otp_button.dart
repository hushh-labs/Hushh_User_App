import 'package:flutter/material.dart';

class ResendOtpButton extends StatelessWidget {
  final int countdownSeconds;
  final bool canResend;
  final VoidCallback? onResend;

  const ResendOtpButton({
    super.key,
    required this.countdownSeconds,
    required this.canResend,
    this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: canResend ? onResend : null,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
          children: <TextSpan>[
            const TextSpan(text: "Didn't receive? "),
            TextSpan(
              text: canResend
                  ? 'Resend'
                  : 'Resend in $countdownSeconds seconds',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: canResend ? TextDecoration.underline : null,
                color: canResend ? Colors.black : const Color(0xffA3A3A3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
