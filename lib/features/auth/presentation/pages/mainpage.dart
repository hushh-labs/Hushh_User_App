import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'auth.dart';
import '../../domain/enums.dart';
import '../../../../shared/presentation/widgets/clickable_logo.dart';
import '../../../../shared/presentation/widgets/debug_wrapper.dart';
import '../../../../core/services/logger_service.dart';

class MainAuthPage extends StatefulWidget {
  const MainAuthPage({super.key});

  @override
  State<MainAuthPage> createState() => _MainAuthPageState();
}

class _MainAuthPageState extends State<MainAuthPage> {
  @override
  void initState() {
    super.initState();
    // Add some test logs
    logger.log('Main page initialized', level: LogLevel.info, tag: 'MAIN');
    logger.log(
      'Debug overlay feature ready',
      level: LogLevel.info,
      tag: 'DEBUG',
    );
  }

  final List<Map<String, String>> socialMethods = [
    {
      'type': 'Phone',
      'icon': 'assets/phone-icon.svg',
      'text': 'Continue as Phone',
    },
    {
      'type': 'Email',
      'icon': 'assets/mail-icon.svg',
      'text': 'Continue as Email',
    },
    {'type': 'Guest', 'icon': 'assets/guest.svg', 'text': 'Continue as Guest'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DebugWrapper(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.75,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [Color(0xFFF6223C), Color(0xFFA342FF)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClickableLogo(
                                        imagePath: 'assets/hushh_s_logo_v1.png',
                                        color: Colors.white,
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.33,
                                        fit: BoxFit.fill,
                                        height:
                                            MediaQuery.of(context).size.width *
                                            0.33 *
                                            1.2,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Hushh 🤫',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              letterSpacing: -1,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Unlock the power of your data',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Column(
                                  children: List.generate(
                                    socialMethods.length,
                                    (index) =>
                                        SocialButton(
                                              text:
                                                  socialMethods[index]['text']!,
                                              iconPath:
                                                  socialMethods[index]['icon']!,
                                              onTap: () {
                                                // TODO: Replace with proper logging
                                                // print(
                                                //   '${socialMethods[index]['type']} button tapped',
                                                // );

                                                // Show bottom sheet based on type
                                                if (socialMethods[index]['type'] ==
                                                    'Phone') {
                                                  _showAuthBottomSheet(
                                                    context,
                                                    LoginMode.phone,
                                                  );
                                                } else if (socialMethods[index]['type'] ==
                                                    'Email') {
                                                  _showAuthBottomSheet(
                                                    context,
                                                    LoginMode.email,
                                                  );
                                                } else if (socialMethods[index]['type'] ==
                                                    'Guest') {
                                                  // Handle guest login
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Guest login tapped',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            )
                                            .animate(delay: (300 * index).ms)
                                            .fade(duration: 700.ms)
                                            .moveX(duration: 800.ms),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Legal text at the bottom with minimal spacing
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 2.0,
                ),
                child: Text.rich(
                  TextSpan(
                    text: "By entering information, I agree to Hushh's ",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(color: Color(0xFFE54D60)),
                      ),
                      const TextSpan(text: ', '),
                      TextSpan(
                        text: 'Non-discrimination Policy',
                        style: const TextStyle(color: Color(0xFFE54D60)),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Payments Terms of Service',
                        style: const TextStyle(color: Color(0xFFE54D60)),
                      ),
                      const TextSpan(text: ' and acknowledge the '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(color: Color(0xFFE54D60)),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAuthBottomSheet(BuildContext context, LoginMode loginMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthPage(loginMode: loginMode),
    );
  }
}

class SocialButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
