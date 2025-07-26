import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CustomTextField extends StatelessWidget {
  final EdgeInsets? edgeInsets;
  final String? hintText;
  final bool showPrefix;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final TextInputType? textInputType;
  final FocusNode? focusNode;
  final double? height;
  final Widget? trailing;

  const CustomTextField({
    super.key,
    this.edgeInsets,
    this.hintText,
    this.showPrefix = true,
    this.controller,
    this.onChanged,
    this.textInputType,
    this.focusNode,
    this.height, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: edgeInsets ??
          EdgeInsets.only(bottom: 100.h / 50.75, top: 100.h / 50.75),
      child: SizedBox(
        height: height ?? 40,
        child: TextFormField(
          autofocus: false,
          controller: controller,
          keyboardType: textInputType,
          focusNode: focusNode,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14.0, color: Color(0xff181941)),
          decoration: InputDecoration(
            // suffix: trailing,
            suffixIcon: trailing,
            contentPadding: !showPrefix
                ? const EdgeInsets.symmetric(horizontal: 8)
                : EdgeInsets.zero,
            filled: true,
            fillColor: Colors.white,
            hintText: hintText ?? 'Search',
            hintStyle: const TextStyle(
                fontSize: 16.0,
                color: Color(0xFF7f7f97),
                fontWeight: FontWeight.w300),
            prefixIcon: showPrefix
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: SvgPicture.asset(
                      'assets/search_new.svg',
                      color: const Color(0xFF616180),
                    ),
                  )
                : null,
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: CupertinoColors.extraLightBackgroundGray,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(
              borderSide: const BorderSide(
                color: CupertinoColors.extraLightBackgroundGray,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: CupertinoColors.extraLightBackgroundGray,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
