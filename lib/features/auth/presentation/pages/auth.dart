// app/platforms/mobile/auth/presentation/pages/auth.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/country_code_text_field.dart';
import '../widgets/email_text_field.dart';
import '../widgets/phone_number_text_field.dart';
import '../widgets/sign_in_with_email_button.dart';
import '../../domain/enums.dart';
import 'otp_verification.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/utils/utils.dart';

class AuthPage extends StatefulWidget {
  final LoginMode loginMode;

  const AuthPage({super.key, this.loginMode = LoginMode.phone});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(InitializeEvent(true));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (widget.loginMode == LoginMode.email) {
      // Navigate to email OTP verification
      context.go(
        RoutePaths.otpVerification,
        extra: OtpVerificationPageArgs(
          emailOrPhone: _emailController.text,
          type: OtpVerificationType.email,
        ),
      );
    } else {
      // Send OTP directly from auth page
      final authBloc = context.read<AuthBloc>();
      final phoneDigits = authBloc.phoneNumberWithoutCountryCode;
      final countryCode = authBloc.selectedCountry?.dialCode ?? '91';
      final fullPhoneNumber = '+$countryCode$phoneDigits';

      print('Sending OTP from auth page to: $fullPhoneNumber');

      // Send OTP - navigation will be handled by BLoC callback
      authBloc.add(SendPhoneOtpEvent(fullPhoneNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OtpSentFailureState) {
          // Show error dialog with retry option
          _showErrorDialog(context, state.message);
        } else if (state is OtpSentState) {
          // OTP sent successfully, navigation will be handled by BLoC callback
          print('OTP sent successfully, waiting for navigation...');
        }
      },
      child: Container(
        color: Colors.white,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD8DADC)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_sharp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SvgPicture.asset('assets/star-icon.svg'),
                  ],
                ),
                const SizedBox(height: 26),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Log in to your account',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.loginMode == LoginMode.email
                        ? 'Welcome! Please enter your email address. We\'ll send you an OTP to verify.'
                        : 'Welcome! Please enter your phone number. We\'ll send you an OTP to verify.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                if (widget.loginMode == LoginMode.email) ...[
                  EmailTextField(controller: _emailController),
                  const SizedBox(height: 20),
                  SignInWithEmailButton(onPressed: _sendOtp),
                ] else ...[
                  const CountryCodeTextField(),
                  const SizedBox(height: 8),
                  const PhoneNumberTextField(),
                  const SizedBox(height: 20),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return InkWell(
                        onTap: state is SendingOtpState ? null : _sendOtp,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0XFFA342FF), Color(0XFFE54D60)],
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: state is SendingOtpState
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
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
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              if (DevelopmentHelper.isDevelopment &&
                  errorMessage.contains('Too many OTP requests')) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Development Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This is a common issue during development. Try:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Wait 5-10 minutes before retrying\n• Use a different phone number\n• Check Firebase console for quota limits',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            if (DevelopmentHelper.isDevelopment &&
                errorMessage.contains('Too many OTP requests')) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Show a snackbar with development tip
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        DevelopmentHelper.getDevelopmentTip(
                          'too-many-requests',
                        ),
                      ),
                      duration: const Duration(seconds: 8),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Development Tip'),
              ),
            ],
          ],
        );
      },
    );
  }
}
