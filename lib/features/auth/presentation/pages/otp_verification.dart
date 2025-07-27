import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/create_first_card.dart';
import '../widgets/otp_heading_section.dart';
import '../widgets/otp_text_field.dart';
import '../../domain/enums.dart';

class OtpVerificationPageArgs {
  final String emailOrPhone;
  final OtpVerificationType type;

  OtpVerificationPageArgs({required this.emailOrPhone, required this.type});
}

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

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
    final args =
        ModalRoute.of(context)!.settings.arguments as OtpVerificationPageArgs;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                    InkWell(
                      onTap: () {
                        // TODO: Replace with proper logging
                        // print('🔥 [OTP_VERIFICATION] Verify button tapped!');
                        // print('🔥 [OTP_VERIFICATION] OTP entered: ${otpController.text}');
                        // print('🔥 [OTP_VERIFICATION] OTP length: ${otpController.text.length}');
                        // print('🔥 [OTP_VERIFICATION] Verification type: ${args.type}');

                        // Navigate to create first card page after OTP verification
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateFirstCardPage(),
                            settings: RouteSettings(
                              arguments: CreateFirstCardPageArgs(
                                initialLoginType: args.type,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0XFFA342FF), Color(0XFFE54D60)],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Center(
                          child: Text(
                            "Verify",
                            style: TextStyle(
                              color: Color(0xffFFFFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
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
                                      countDownForResendStartValue.toString() ==
                                          "60"
                                      ? TextDecoration.underline
                                      : null,
                                  color:
                                      countDownForResendStartValue.toString() ==
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
                                      countDownForResendStartValue.toString() ==
                                          "60"
                                      ? TextDecoration.underline
                                      : null,
                                  color:
                                      countDownForResendStartValue.toString() ==
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
    );
  }
}
