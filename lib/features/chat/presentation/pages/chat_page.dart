import 'package:flutter/material.dart';
import '../../../../shared/utils/app_local_storage.dart';
import '../../../../shared/utils/guest_access_control.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is in guest mode
    if (AppLocalStorage.isGuestMode) {
      return _buildGuestLockedUI();
    }

    // If not guest, show normal chat page
    return _buildNormalChatUI();
  }

  Widget _buildGuestLockedUI() {
    return Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Chat Feature Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to unlock chat functionality and start conversations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  GuestAccessControl.showGuestAccessPopup(
                    context,
                    featureName: 'Chat',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA342FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In to Unlock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalChatUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Color(0xFF6C63FF)),
            SizedBox(height: 24),
            Text(
              'Chat Coming Soon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Chat functionality will be available soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
