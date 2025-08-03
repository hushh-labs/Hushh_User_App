import 'package:flutter/material.dart';
import 'debug_overlay.dart';

class DebugWrapper extends StatelessWidget {
  final Widget child;

  const DebugWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [child, const DebugOverlay()]);
  }
}
