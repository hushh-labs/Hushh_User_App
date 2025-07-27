import 'package:flutter/material.dart';

// Simple Toast Manager without complex dependencies
class Toast {
  final String? title;
  final String? description;
  final bool showProgress;
  final Duration duration;
  final ToastType type;

  Toast({
    this.title,
    this.description,
    this.showProgress = true,
    this.duration = const Duration(seconds: 3),
    this.type = ToastType.info,
  });
}

enum ToastType { success, error, warning, info }

class ToastManager {
  final Toast toast;

  ToastManager(this.toast);

  void show(BuildContext context, {Alignment? alignment}) {
    if (toast.title != null) {
      _showSnackBar(context);
    }
  }

  void _showSnackBar(BuildContext context) {
    Color backgroundColor;
    IconData iconData;
    Color iconColor;

    switch (toast.type) {
      case ToastType.success:
        backgroundColor = Colors.green;
        iconData = Icons.check_circle;
        iconColor = Colors.white;
        break;
      case ToastType.error:
        backgroundColor = Colors.red;
        iconData = Icons.error;
        iconColor = Colors.white;
        break;
      case ToastType.warning:
        backgroundColor = Colors.orange;
        iconData = Icons.warning;
        iconColor = Colors.white;
        break;
      case ToastType.info:
        backgroundColor = Colors.blue;
        iconData = Icons.info;
        iconColor = Colors.white;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (toast.title != null)
                    Text(
                      toast.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  if (toast.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      toast.description!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: toast.duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
