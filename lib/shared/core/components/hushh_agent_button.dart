import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HushhLinearGradientButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final IconData? icon;
  final Function() onTap;
  final double? radius;
  final double? height;
  final bool loader;
  final bool trailing;
  final double? fontSize;
  final Color? color;
  final Widget? trailingWidget;

  const HushhLinearGradientButton(
      {super.key,
      required this.text,
      required this.onTap,
      this.enabled = true,
      this.loader = false,
      this.trailing = false,
      this.icon,
      this.fontSize,
      this.color,
      this.radius,
      this.height,
      this.trailingWidget});

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
              borderRadius: BorderRadius.circular(radius ?? 43),
              color: enabled ? (color) : Colors.grey,
              gradient: enabled
                  ? color != null
                      ? null
                      : const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                              Color(0xFFA342FF),
                              Color(0xFFE54D60),
                            ])
                  : null),
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!trailing)
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 16),
                        ],
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: fontSize),
                      ),
                    ],
                  ),
                ),
              ),
              if (trailing)
                if (icon != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    icon,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                ] else if (trailingWidget != null)
                  trailingWidget!,
              if (loader) ...[
                const SizedBox(width: 8),
                const CupertinoActivityIndicator(color: Colors.white)
              ]
            ],
          ),
        ),
      ),
    );
  }
}
