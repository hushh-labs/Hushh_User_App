import 'package:flutter/material.dart';

class EmailInputButton extends StatefulWidget {
  const EmailInputButton({super.key});

  @override
  State<EmailInputButton> createState() => _EmailInputButtonState();
}

class _EmailInputButtonState extends State<EmailInputButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
