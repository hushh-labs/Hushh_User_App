import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:hushh_user_app/core/services/firebase_service.dart';
import 'package:hushh_user_app/core/routing/route_paths.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Warning Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 40,
                  color: Colors.red[600],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Delete Your Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Warning Text
            Text(
              'This action cannot be undone. Once you delete your account, all your data will be permanently removed from our servers.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // What will be deleted
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What will be deleted:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDeleteItem('Your profile information'),
                  _buildDeleteItem('All your cards and wallet data'),
                  _buildDeleteItem('Chat history and messages'),
                  _buildDeleteItem('Notification preferences'),
                  _buildDeleteItem('Account settings and preferences'),
                ],
              ),
            ),

            const Spacer(),

            // Delete Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _showDeleteConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _isDeleting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you absolutely sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final firebaseService = GetIt.instance<FirebaseService>();
      final currentUser = firebaseService.getCurrentUser();

      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      // Check if user needs re-authentication before deletion
      final needsReauth = await firebaseService.needsReauthentication();
      if (needsReauth) {
        setState(() {
          _isDeleting = false;
        });
        _showReauthenticationRequiredDialog();
        return;
      }

      // Delete user data from Firestore first
      await firebaseService.deleteUserData(currentUser.uid);

      // Delete user from Firebase Auth
      await firebaseService.deleteUser();

      // Navigate to auth page
      if (mounted) {
        context.go(RoutePaths.mainAuth);
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });

      if (mounted) {
        _showErrorDialog('Failed to delete account', e.toString());
      }
    }
  }

  void _showReauthenticationRequiredDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Re-authentication Required'),
          content: const Text(
            'For security reasons, you need to sign in again before deleting your account. This is a Firebase security requirement.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _signOutAndNavigateToAuth();
              },
              isDefaultAction: true,
              child: const Text('Sign In Again'),
            ),
          ],
        );
      },
    );
  }

  void _signOutAndNavigateToAuth() async {
    try {
      final firebaseService = GetIt.instance<FirebaseService>();
      await firebaseService.signOut();
      if (mounted) {
        context.go(RoutePaths.mainAuth);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to sign out', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            // Add additional action for re-authentication if needed
            if (message.contains('Recent authentication required')) ...[
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  _handleReauthentication();
                },
                isDefaultAction: true,
                child: const Text('Sign In Again'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _handleReauthentication() {
    // Navigate to auth page for re-authentication
    context.go(RoutePaths.mainAuth);
  }
}
