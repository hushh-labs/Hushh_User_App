// Enhanced Profile page with improved UI
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hushh_user_app/shared/utils/app_local_storage.dart';
import 'package:hushh_user_app/shared/constants/app_routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  String _appVersion = '';
  String _buildNumber = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _getAppInfo();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Enhanced Profile Header
                _buildEnhancedProfileHeader(),

                const SizedBox(height: 20),

                // Enhanced Essential Options
                _buildEnhancedEssentialOptions(),

                const SizedBox(height: 24),

                // Enhanced App Version
                _buildAppVersionCard(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA342FF).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: _buildUserProfileHeader(),
    );
  }

  Widget _buildUserProfileHeader() {
    final user = AppLocalStorage.user;
    final displayName = user?.name?.isNotEmpty == true
        ? user!.name!
        : 'Update your name';
    final phoneNumber = user?.phoneNumber?.isNotEmpty == true
        ? user!.phoneNumber!
        : 'Add phone number';
    final email = user?.email?.isNotEmpty == true
        ? user!.email!
        : 'Add email address';

    return Column(
      children: [
        Row(
          children: [
            // Enhanced Profile Avatar
            Hero(
              tag: 'profile_avatar',
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA342FF).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: user?.avatar?.isNotEmpty == true
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user!.avatar!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[50],
                              ),
                              child: Icon(
                                Icons.person,
                                size: 35,
                                color: Colors.grey[400],
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[50],
                              ),
                              child: Icon(
                                Icons.person,
                                size: 35,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[50],
                          ),
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Enhanced Profile Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 2,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.email_outlined,
                    email,
                    user?.email?.isNotEmpty == true,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.phone_outlined,
                    phoneNumber,
                    user?.phoneNumber?.isNotEmpty == true,
                  ),
                ],
              ),
            ),

            // Enhanced Edit Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA342FF).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showEditProfileBottomSheet(context),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool hasValue) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: hasValue ? const Color(0xFFA342FF) : Colors.grey[400],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: hasValue ? Colors.black87 : Colors.grey[500],
              fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedEssentialOptions() {
    return Column(
      children: [
        _buildSectionTitle('Manage'),
        const SizedBox(height: 12),
        _buildMenuCard([
          _MenuItemData('Notifications', Icons.notifications_outlined, () {
            try {
              Navigator.pushNamed(context, AppRoutes.cardWallet.notifications);
            } catch (e) {
              _showErrorSnackBar(
                'Unable to open Notifications: ${e.toString()}',
              );
            }
          }),
          _MenuItemData('Permissions', Icons.security_outlined, () {
            try {
              Navigator.pushNamed(context, AppRoutes.permissions);
            } catch (e) {
              _showErrorSnackBar('Unable to open Permissions');
            }
          }),
          _MenuItemData(
            'Wallet & Cards',
            Icons.account_balance_wallet_outlined,
            () {
              try {
                Navigator.pushNamed(context, AppRoutes.home);
              } catch (e) {
                _showErrorSnackBar('Unable to open Wallet & Cards');
              }
            },
          ),
        ]),

        const SizedBox(height: 20),

        _buildSectionTitle('More'),
        const SizedBox(height: 12),
        _buildMenuCard([
          _MenuItemData('Send Feedback', Icons.rate_review_outlined, () {
            try {
              _showErrorSnackBar('Feedback feature coming soon!');
            } catch (e) {
              _showErrorSnackBar('Unable to open Send Feedback');
            }
          }),
          if (!kIsWeb) ...[
            _MenuItemData('Delete Account', Icons.delete_outline, () {
              try {
                Navigator.pushNamed(context, AppRoutes.deleteAccount);
              } catch (e) {
                _showErrorSnackBar('Unable to open Delete Account');
              }
            }),
            _MenuItemData('Logout', Icons.logout_outlined, () {
              try {
                _showLogoutDialog();
              } catch (e) {
                _showErrorSnackBar('Unable to open Logout dialog');
              }
            }, showArrow: false),
          ],
        ]),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA342FF).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isFirst = index == 0;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              _buildEnhancedMenuItem(
                item.title,
                item.icon,
                item.onTap,
                isFirst: isFirst,
                isLast: isLast,
                showArrow: item.showArrow,
              ),
              if (!isLast) _buildDivider(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedMenuItem(
    String title,
    IconData icon,
    VoidCallback? onTap, {
    bool isFirst = false,
    bool isLast = false,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA342FF).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      height: 1,
      color: Colors.grey[100],
    );
  }

  Widget _buildAppVersionCard() {
    return Center(
      child: Text(
        _appVersion.isNotEmpty && _buildNumber.isNotEmpty
            ? 'Version $_appVersion • Build $_buildNumber'
            : 'Loading version info...',
        style: TextStyle(color: Colors.grey[600], fontSize: 16),
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context) {
    _showEditUserProfileBottomSheet(context);
  }

  void _showEditUserProfileBottomSheet(BuildContext context) {
    final user = AppLocalStorage.user;
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(
      text: user?.phoneNumber ?? '',
    );
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Enhanced Profile Photo Section
                    Center(
                      child: Stack(
                        children: [
                          Hero(
                            tag: 'edit_profile_avatar',
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFA342FF),
                                    Color(0xFFE54D60),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFA342FF,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: selectedImagePath != null
                                    ? ClipOval(
                                        child: Image.file(
                                          File(selectedImagePath!),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (user?.avatar?.isNotEmpty == true
                                          ? ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: user!.avatar!,
                                                fit: BoxFit.cover,
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.grey[50],
                                                      ),
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 45,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey[50],
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                size: 45,
                                                color: Colors.grey[400],
                                              ),
                                            )),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 3,
                            right: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFA342FF),
                                    Color(0xFFE54D60),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFA342FF,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      _pickProfileImage(setModalState, (path) {
                                        selectedImagePath = path;
                                      }),
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Enhanced Input Fields
                    _buildInputField('Name', nameController, 'Enter your name'),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'Phone Number',
                      phoneController,
                      'Enter your phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Enhanced Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _saveProfile(
                          context,
                          nameController.text,
                          phoneController.text,
                          selectedImagePath,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFA342FF,
                                ).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFA342FF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickProfileImage(
    StateSetter setModalState,
    Function(String) onImageSelected,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setModalState(() {
          onImageSelected(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Unable to pick image');
    }
  }

  void _saveProfile(
    BuildContext context,
    String name,
    String phone,
    String? imagePath,
  ) async {
    try {
      _showSuccessSnackBar('Profile updated successfully');
      Navigator.pop(context);
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Unable to save profile changes');
    }
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Logged out successfully');
              },
              isDestructiveAction: true,
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _MenuItemData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool showArrow;

  _MenuItemData(this.title, this.icon, this.onTap, {this.showArrow = true});
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
