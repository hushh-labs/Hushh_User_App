import 'package:flutter/material.dart';

class HushhSecondaryButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final IconData? icon;
  final Function() onTap;
  final double? radius;
  final double? height;
  final Color? color;

  const HushhSecondaryButton(
      {super.key,
      required this.text,
      required this.onTap,
      this.enabled = true,
      this.icon,
      this.radius,
      this.color,
      this.height});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: height,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(radius ?? 43),
              border: Border.all(color: Colors.black)),
          child: icon == null
              ? Center(
                  child: Text(
                    text,
                    style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      icon,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      text,
                      style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
