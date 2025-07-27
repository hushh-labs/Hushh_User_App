import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class CountryCodeTextField extends StatefulWidget {
  final bool onlyCode;

  const CountryCodeTextField({super.key, this.onlyCode = false});

  @override
  State<CountryCodeTextField> createState() => _CountryCodeTextFieldState();
}

class _CountryCodeTextFieldState extends State<CountryCodeTextField> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final authBloc = context.read<AuthBloc>();
        return SizedBox(
          height: 56,
          child: TextFormField(
            autovalidateMode: AutovalidateMode.disabled,
            readOnly: true,
            cursorColor: const Color.fromARGB(
              255,
              179,
              183,
              189,
            ).withValues(alpha: 0.5),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
            onTap: () => authBloc.add(OnCountryUpdateEvent(context)),
            controller: TextEditingController(
              text: authBloc.selectedCountry == null
                  ? ""
                  : widget.onlyCode
                  ? '+${authBloc.selectedCountry!.dialCode}'
                  : '${authBloc.selectedCountry!.name} (+${authBloc.selectedCountry!.dialCode})',
            ),
            keyboardAppearance: Brightness.light,
            decoration: InputDecoration(
              contentPadding: widget.onlyCode
                  ? null
                  : const EdgeInsets.symmetric(horizontal: 10),
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (authBloc.selectedCountry != null)
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: Text(
                        authBloc.selectedCountry!.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                ],
              ),
              border: widget.onlyCode
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xff8391a1).withValues(alpha: 0.5),
                      ),
                    ),
              enabledBorder: widget.onlyCode
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xff8391a1).withValues(alpha: 0.5),
                      ),
                    ),
              focusedBorder: widget.onlyCode
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xff8391a1).withValues(alpha: 0.5),
                      ),
                    ),
              disabledBorder: widget.onlyCode
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xff8391a1).withValues(alpha: 0.5),
                      ),
                    ),
              errorBorder: widget.onlyCode
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color(0xff8391a1).withValues(alpha: 0.5),
                      ),
                    ),
              focusedErrorBorder: widget.onlyCode
                  ? InputBorder.none
                  : OutlineInputBorder(
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
