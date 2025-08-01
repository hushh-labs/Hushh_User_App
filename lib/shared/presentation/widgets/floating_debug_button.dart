import 'package:flutter/material.dart';
import '../../../core/services/logger_service.dart';

class FloatingDebugButton extends StatefulWidget {
  const FloatingDebugButton({super.key});

  @override
  State<FloatingDebugButton> createState() => _FloatingDebugButtonState();
}

class _FloatingDebugButtonState extends State<FloatingDebugButton> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _isVisible = logger.isVisible;

    // Add a test log to demonstrate the feature
    logger.log(
      'Floating debug button initialized - tap to toggle logs',
      level: LogLevel.info,
      tag: 'DEBUG',
    );

    logger.visibilityStream.listen((isVisible) {
      if (mounted) {
        setState(() {
          _isVisible = isVisible;
        });
      }
    });
  }

  void _toggleDebugOverlay() {
    logger.log(
      'Debug overlay toggled via floating button',
      level: LogLevel.info,
      tag: 'DEBUG',
    );
    logger.toggleVisibility();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _toggleDebugOverlay,
          backgroundColor: _isVisible ? Colors.red : Colors.grey.shade700,
          mini: true,
          tooltip: _isVisible ? 'Hide Debug Logs' : 'Show Debug Logs',
          child: Icon(
            _isVisible ? Icons.bug_report : Icons.bug_report_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
