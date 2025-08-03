import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/otp_text_field.dart';

class EmailVerificationPageArgs {
  final String email;
  final Function()? onVerify;

  EmailVerificationPageArgs(this.email, {this.onVerify});
}

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final TextEditingController controller = TextEditingController();
  int countDownForResendStartValue = 60;
  late Timer countDownForResend;
  bool resendValidation = false;

  void countDownForResendFunction() {
    const oneSec = Duration(seconds: 1);
    countDownForResend = Timer.periodic(
      oneSec,
      (Timer timer) {
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
      },
    );
  }

  @override
  void initState() {
    countDownForResendFunction();
    super.initState();
  }

  @override
  void dispose() {
    countDownForResend.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as EmailVerificationPageArgs;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                            border: Border.all(color: const Color(0xFFD8DADC))),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_sharp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SvgPicture.asset('assets/star-icon.svg')
                  ],
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.2,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Verify your email',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We sent a verification code to\n${args.email}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OtpTextField(
                  controller: controller,
                  onCompleted: (otp) {
                    // Handle OTP verification
                    if (args.onVerify != null) {
                      args.onVerify!();
                    }
                  },
                ),
                const SizedBox(height: 20),
                if (resendValidation)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        resendValidation = false;
                        countDownForResendStartValue = 60;
                      });
                      countDownForResendFunction();
                    },
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  Text(
                    'Resend code in ${countDownForResendStartValue}s',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
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