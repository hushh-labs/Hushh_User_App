import 'package:flutter/material.dart';
import '../../../core/services/logger_service.dart';

class ClickableLogo extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit? fit;

  const ClickableLogo({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.color,
    this.fit,
  });

  @override
  State<ClickableLogo> createState() => _ClickableLogoState();
}

class _ClickableLogoState extends State<ClickableLogo> {
  int _clickCount = 0;
  DateTime? _lastClickTime;
  static const Duration _clickTimeout = Duration(milliseconds: 2000);

  void _handleTap() {
    final now = DateTime.now();

    // Reset click count if too much time has passed
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!) > _clickTimeout) {
      _clickCount = 0;
    }

    _clickCount++;
    _lastClickTime = now;

    // Log the click
    logger.log(
      'Logo clicked $_clickCount times',
      level: LogLevel.debug,
      tag: 'LOGO',
    );

    // If 5 clicks detected, toggle debug overlay
    if (_clickCount >= 5) {
      logger.log(
        'Debug overlay toggled by 5 logo clicks',
        level: LogLevel.info,
        tag: 'DEBUG',
      );
      logger.toggleVisibility();
      _clickCount = 0; // Reset counter
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Image.asset(
        widget.imagePath,
        width: widget.width,
        height: widget.height,
        color: widget.color,
        fit: widget.fit ?? BoxFit.contain,
      ),
    );
  }
}
