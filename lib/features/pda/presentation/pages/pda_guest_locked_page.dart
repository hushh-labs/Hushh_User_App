import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/cupertino.dart';

import 'package:hushh_user_app/shared/utils/app_local_storage.dart';
import 'package:hushh_user_app/shared/constants/app_routes.dart';
import 'package:hushh_user_app/shared/utils/guest_access_control.dart';
import 'package:hushh_user_app/shared/widgets/user_coins_elevated_button.dart';
import 'package:hushh_user_app/features/pda/presentation/pages/pda_simple_page.dart';

class PdaGuestLockedPage extends StatefulWidget {
  const PdaGuestLockedPage({super.key});

  @override
  State<PdaGuestLockedPage> createState() => _PdaGuestLockedPageState();
}

class _PdaGuestLockedPageState extends State<PdaGuestLockedPage> {
  @override
  Widget build(BuildContext context) {
    // Check if user is in guest mode
    if (AppLocalStorage.isGuestMode) {
      return _buildGuestLockedUI();
    }

    // If not guest, show normal PDA page
    return const PdaSimplePage();
  }

  Widget _buildGuestLockedUI() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile icon - simplified for now
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[100],
              child: const Icon(
                CupertinoIcons.person,
                size: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Hushh PDA',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const Icon(Icons.lock_outline, size: 12),
            const Spacer(),
            const UserCoinsElevatedButton(),
            const SizedBox(width: 12),
            InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.cardWallet.notifications,
                );
              },
              child: Transform.scale(
                scale: 1.05,
                child: SvgPicture.asset('assets/noti_icon.svg'),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Color(0xFFF6223C),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'PDA Locked',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Your Personal Digital Assistant is available for registered users only. Sign in to unlock this feature.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Sign In Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFFF6223C), Color(0xFFA342FF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF6223C).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      GuestAccessControl.showGuestAccessPopup(
                        context,
                        featureName: 'pda',
                      );
                    },
                    child: const Center(
                      child: Text(
                        'Sign In to Unlock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Continue as Guest Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      // Navigate to home page to explore other guest-available features
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    },
                    child: const Center(
                      child: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Features Preview
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'What you\'ll get with PDA:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.chat_bubble_outline,
                      'AI-powered conversations',
                    ),
                    _buildFeatureItem(
                      Icons.insights_outlined,
                      'Personalized insights',
                    ),
                    _buildFeatureItem(
                      Icons.security_outlined,
                      'Privacy-focused assistance',
                    ),
                    _buildFeatureItem(
                      Icons.smart_toy_outlined,
                      'Smart recommendations',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF6223C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
