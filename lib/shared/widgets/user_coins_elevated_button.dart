import 'package:flutter/material.dart';

class UserCoinsElevatedButton extends StatelessWidget {
  const UserCoinsElevatedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to coins page - you can implement this later
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coins page coming soon!')),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(38),
          color: Colors.black,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monetization_on, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
