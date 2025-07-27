import 'package:flutter/material.dart';

class OrSeparatorWidget extends StatelessWidget {
  const OrSeparatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Divider(
              thickness: 1.5,
              color: Color(0xffE8ECF4),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "or",
              style: TextStyle(color: Color(0xff6A707C), fontSize: 14),
            ),
          ),
          Expanded(
            child: Divider(
              thickness: 1.5,
              color: Color(0xffE8ECF4),
            ),
          ),
        ],
      ),
    );
  }
}
