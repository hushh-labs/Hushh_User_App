import 'package:flutter/material.dart';
import 'email_input_page.dart';
import 'phone_input_page.dart';
import '../../domain/enums.dart';
import '../../../../shared/utils/app_local_storage.dart';

class CreateFirstCardPageArgs {
  final OtpVerificationType initialLoginType;

  CreateFirstCardPageArgs({required this.initialLoginType});
}

class CreateFirstCardPage extends StatefulWidget {
  final CreateFirstCardPageArgs? args;

  const CreateFirstCardPage({super.key, this.args});

  @override
  State<CreateFirstCardPage> createState() => _CreateFirstCardPageState();
}

class _CreateFirstCardPageState extends State<CreateFirstCardPage> {
  OtpVerificationType? _loginType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineLoginType();
  }

  Future<void> _determineLoginType() async {
    if (widget.args != null) {
      // If args are provided, use the initial login type
      _loginType = widget.args!.initialLoginType;
    } else {
      // If no args provided, try to get the stored login type
      _loginType = await AppLocalStorage.getLoginType();
      // If no stored login type, default to phone (most common case)
      _loginType ??= OtpVerificationType.phone;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
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
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Your Hushh card 🤫',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 20),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/dummy-card.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your data wallet holds digital cards, each organizing a category of your data. Let\'s start with your Hushh ID card by adding your basic details!',
                  style: TextStyle(fontSize: 16, color: Color(0xFF838383)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 52),
                InkWell(
                  onTap: _isLoading
                      ? null
                      : () {
                          // Navigate to the appropriate input page based on login type
                          if (_loginType == OtpVerificationType.phone) {
                            // If phone was used initially, go to email input
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmailInputPage(),
                              ),
                            );
                          } else {
                            // If email was used initially, go to phone input
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PhoneInputPage(),
                              ),
                            );
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0XFFA342FF), Color(0XFFE54D60)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Start Now",
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
          ),
        ),
      ),
    );
  }
}
