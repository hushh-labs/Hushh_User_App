import 'package:flutter/material.dart';
import '../../domain/repositories/gmail_repository.dart';
import 'gmail_sync_dialog.dart';

class GmailBottomModalSheet extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onConnect;
  final VoidCallback onSync;
  final VoidCallback onQuickSync;
  final VoidCallback onDisconnect;

  const GmailBottomModalSheet({
    super.key,
    required this.isConnected,
    required this.onConnect,
    required this.onSync,
    required this.onQuickSync,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mail_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gmail',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          isConnected ? 'Connected' : 'Not connected',
                          style: TextStyle(
                            fontSize: 14,
                            color: isConnected
                                ? Colors.green[600]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Options
            if (isConnected) ...[
              Text(
                'Your Gmail is already connected. What would you like to do?',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _buildOption(
                icon: Icons.logout,
                title: 'Disconnect',
                subtitle: 'Remove Gmail connection',
                onTap: () {
                  Navigator.pop(context);
                  onDisconnect();
                },
                isDestructive: true,
              ),
            ] else ...[
              Text(
                'Connect your Gmail account to sync emails and get personalized assistance.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _buildOption(
                icon: Icons.connect_without_contact,
                title: 'Connect Gmail',
                subtitle: 'Start email sync',
                onTap: () {
                  Navigator.pop(context);
                  onConnect();
                },
              ),
            ],

            // Cancel button
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive ? Colors.red[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red[600] : Colors.grey[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red[600] : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Convenience function to show Gmail bottom modal sheet
Future<void> showGmailBottomModalSheet(
  BuildContext context, {
  required bool isConnected,
  required VoidCallback onConnect,
  required Function(SyncOptions) onSyncSelected,
  required VoidCallback onQuickSync,
  required VoidCallback onDisconnect,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => GmailBottomModalSheet(
      isConnected: isConnected,
      onConnect: onConnect,
      onSync: () async {
        // Show the sync dialog
        await showGmailSyncDialog(context, onSyncSelected: onSyncSelected);
      },
      onQuickSync: onQuickSync,
      onDisconnect: onDisconnect,
    ),
  );
}
