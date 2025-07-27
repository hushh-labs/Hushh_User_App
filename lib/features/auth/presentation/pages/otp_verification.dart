import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/create_first_card.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/discover_page.dart';
import '../widgets/otp_heading_section.dart';
import '../widgets/otp_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/enums.dart';
import '../../domain/entities/user_card.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/utils/utils.dart';
import '../../../../shared/core/utils/toast_manager.dart';

class OtpVerificationPageArgs {
  final String emailOrPhone;
  final OtpVerificationType type;

  OtpVerificationPageArgs({required this.emailOrPhone, required this.type});
}

class OtpVerificationPage extends StatefulWidget {
  final OtpVerificationPageArgs args;
  const OtpVerificationPage({super.key, required this.args});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController otpController = TextEditingController();
  int countDownForResendStartValue = 60;
  late Timer countDownForResend;
  bool resendValidation = false;

  void countDownForResendFunction() {
    const oneSec = Duration(seconds: 1);
    countDownForResend = Timer.periodic(oneSec, (Timer timer) {
      if (countDownForResendStartValue == 0) {
        setState(() {
          timer.cancel();
          resendValidation = true;
          countDownForResendStartValue = 60;
        });
      } else {
        setState(() {
          countDownForResendStartValue--;
        });
      }
    });
  }

  @override
  void initState() {
    otpController.clear();
    countDownForResendFunction();
    super.initState();
  }

  @override
  void dispose() {
    countDownForResend.cancel();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpVerifiedState) {
            // Check if user card exists
            context.read<AuthBloc>().add(
              CheckUserCardEvent(state.userCredential.user!.uid),
            );
          } else if (state is UserCardExistsState) {
            if (state.exists) {
              // Navigate to discover page
              context.go(RoutePaths.discover);
            } else {
              // Navigate to create first card page
              context.push(
                RoutePaths.createFirstCard,
                extra: CreateFirstCardPageArgs(initialLoginType: args.type),
              );
            }
          } else if (state is OtpVerificationFailureState) {
            ToastManager(
              Toast(
                title: 'Verification Failed',
                description: state.message,
                type: ToastType.error,
                duration: const Duration(seconds: 4),
              ),
            ).show(context);
          } else if (state is UserCardCheckFailureState) {
            ToastManager(
              Toast(
                title: 'Error',
                description: 'Failed to check user card: ${state.message}',
                type: ToastType.error,
                duration: const Duration(seconds: 4),
              ),
            ).show(context);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - kToolbarHeight,
              padding: const EdgeInsets.all(20.0).copyWith(top: 12),
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
                  const SizedBox(height: 26 * 3),
                  OtpHeadingSection(
                    title: args.type == OtpVerificationType.email
                        ? 'Verify your Email'
                        : 'Verify your phone number',
                    subtitle: args.type == OtpVerificationType.email
                        ? "We've sent an OTP with an activation code to your email "
                        : "We've sent an SMS with an activation code to your phone ",
                    emailOrPhone: args.emailOrPhone,
                  ),
                  const Expanded(child: SizedBox()),
                  Expanded(
                    flex: 10,
                    child: OtpTextField(
                      controller: otpController,
                      onCompleted: (String value) {
                        // Handle OTP completion
                        // TODO: Replace with proper logging
                        // print('OTP completed: $value');
                      },
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return InkWell(
                            onTap: state is VerifyingOtpState
                                ? null
                                : () {
                                    if (otpController.text.length == 6) {
                                      context.read<AuthBloc>().add(
                                        VerifyPhoneOtpEvent(
                                          phoneNumber: args.emailOrPhone,
                                          otp: otpController.text,
                                        ),
                                      );
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0XFFA342FF),
                                    Color(0XFFE54D60),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: state is VerifyingOtpState
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Verify",
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
                  ),
                  TextButton(
                    onPressed: () {
                      if (countDownForResendStartValue.toString() == "60") {
                        countDownForResendFunction();
                        // TODO: Replace with proper logging
                        // print('🔥 [OTP_VERIFICATION] Resend OTP for: ${args.emailOrPhone}');
                        // print('🔥 [OTP_VERIFICATION] Type: ${args.type}');
                      }
                    },
                    child: countDownForResendStartValue.toString().length == 1
                        ? RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                              children: <TextSpan>[
                                const TextSpan(text: "Didn't receive?"),
                                TextSpan(
                                  text: ' Resend',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration:
                                        countDownForResendStartValue
                                                .toString() ==
                                            "60"
                                        ? TextDecoration.underline
                                        : null,
                                    color:
                                        countDownForResendStartValue
                                                .toString() ==
                                            "60"
                                        ? Colors.black
                                        : const Color(0xffA3A3A3),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' in 0$countDownForResendStartValue seconds',
                                ),
                              ],
                            ),
                          )
                        : RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                              children: <TextSpan>[
                                const TextSpan(text: "Didn't receive? "),
                                TextSpan(
                                  text: 'Resend',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration:
                                        countDownForResendStartValue
                                                .toString() ==
                                            "60"
                                        ? TextDecoration.underline
                                        : null,
                                    color:
                                        countDownForResendStartValue
                                                .toString() ==
                                            "60"
                                        ? Colors.black
                                        : const Color(0xffA3A3A3),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' in $countDownForResendStartValue seconds',
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
