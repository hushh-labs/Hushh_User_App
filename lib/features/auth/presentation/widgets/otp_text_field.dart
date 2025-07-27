import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpTextField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onCompleted;

  const OtpTextField({super.key, required this.controller, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      focusNode: FocusNode(),
      enablePinAutofill: true,
      useExternalAutoFillGroup: true,
      autoDisposeControllers: false,
      appContext: context,
      cursorColor: const Color(0xffDFE2E8),
      onChanged: (String value) {},
      onCompleted: onCompleted,
      textStyle:
          const TextStyle(fontSize: 15, height: 1.5, color: Colors.black),
      controller: controller,
      keyboardType: TextInputType.number,
      keyboardAppearance: Brightness.light,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        fieldOuterPadding: const EdgeInsets.only(right: 0),
        inactiveColor: const Color(0xffDFE2E8),
        selectedColor: const Color(0xffDFE2E8),
        activeColor: const Color(0xffDFE2E8),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderWidth: 1,
        fieldHeight: 50,
        activeFillColor: const Color(0xffDFE2E8),
      ),
      length: 6,
    );
  }
}
