// app/platforms/mobile/auth/presentation/pages/auth.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/country_code_text_field.dart';
import '../widgets/email_text_field.dart';
import '../widgets/phone_number_text_field.dart';
import '../widgets/sign_in_with_email_button.dart';
import '../widgets/sign_in_with_phone_button.dart';
import '../../domain/enums.dart';
import 'otp_verification.dart';

class AuthPage extends StatefulWidget {
  final LoginMode loginMode;

  const AuthPage({super.key, this.loginMode = LoginMode.phone});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AuthBloc authBloc;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    authBloc = AuthBloc();
    authBloc.add(InitializeEvent(true));
  }

  @override
  void dispose() {
    authBloc.close();
    _emailController.dispose();
    super.dispose();
  }

  void _navigateToOtpVerification() {
    if (widget.loginMode == LoginMode.email) {
      // Navigate to email OTP verification
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OtpVerificationPage(),
          settings: RouteSettings(
            arguments: OtpVerificationPageArgs(
              emailOrPhone: _emailController.text,
              type: OtpVerificationType.email,
            ),
          ),
        ),
      );
    } else {
      // Navigate to phone OTP verification
      final phoneNumber = authBloc.phoneController.text;
      final countryCode = authBloc.selectedCountry?.dialCode ?? '91';
      final fullPhoneNumber = '+$countryCode$phoneNumber';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OtpVerificationPage(),
          settings: RouteSettings(
            arguments: OtpVerificationPageArgs(
              emailOrPhone: fullPhoneNumber,
              type: OtpVerificationType.phone,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => authBloc,
      child: Container(
        color: Colors.white,
        height: MediaQuery.of(context).size.height * 0.7,
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
                const Spacer(),
                SignInWithEmailButton(onPressed: _navigateToOtpVerification),
              ] else ...[
                const CountryCodeTextField(),
                const SizedBox(height: 8),
                const PhoneNumberTextField(),
                const Spacer(),
                SignInWithPhoneButton(onPressed: _navigateToOtpVerification),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
