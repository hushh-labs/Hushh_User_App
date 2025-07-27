import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class PhoneNumberTextField extends StatefulWidget {
  const PhoneNumberTextField({super.key});

  @override
  State<PhoneNumberTextField> createState() => _PhoneNumberTextFieldState();
}

class _PhoneNumberTextFieldState extends State<PhoneNumberTextField> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final authBloc = context.read<AuthBloc>();
        return SizedBox(
          height: 56,
          child: TextFormField(
            autovalidateMode: AutovalidateMode.disabled,
            inputFormatters: [
              if (authBloc.formatter != null) authBloc.formatter!,
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            cursorColor: const Color.fromARGB(
              255,
              179,
              183,
              189,
            ).withValues(alpha: 0.5),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w300,
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
            controller: authBloc.phoneController,
            onChanged: (value) {
              authBloc.add(OnPhoneUpdateEvent(value));
            },
            keyboardAppearance: Brightness.light,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              hintText: "Enter mobile number",
              hintStyle: TextStyle(
                color: const Color.fromARGB(
                  255,
                  179,
                  183,
                  189,
                ).withValues(alpha: 0.5),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: const Color(0xff8391a1).withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: const Color(0xff8391a1).withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: const Color(0xff8391a1).withValues(alpha: 0.5),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: const Color(0xff8391a1).withValues(alpha: 0.5),
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: const Color(0xff8391a1).withValues(alpha: 0.5),
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: const Color(0xff8391a1).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
