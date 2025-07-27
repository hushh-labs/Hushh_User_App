import 'package:flutter/material.dart';

class SignInWithPhoneButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SignInWithPhoneButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          onPressed ??
          () {
            // Simple navigation or callback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone sign in tapped')),
            );
          },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0XFFA342FF), Color(0XFFE54D60)],
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Center(
          child: Text(
            "Continue",
            style: TextStyle(
              color: Color(0xffFFFFFF),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
