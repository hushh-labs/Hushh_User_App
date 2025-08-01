import 'package:flutter/material.dart';
import '../../../core/services/logger_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DebugOverlay extends StatefulWidget {
  const DebugOverlay({super.key});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  List<LogEntry> _logs = [];
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _isVisible = logger.isVisible;
    _logs = logger.logs;

    logger.logsStream.listen((logs) {
      if (mounted) {
        setState(() {
          _logs = logs;
        });
      }
    });

    logger.visibilityStream.listen((isVisible) {
      if (mounted) {
        setState(() {
          _isVisible = isVisible;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Debug Logs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => logger.clear(),
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.white,
                            size: 24,
                          ),
                          tooltip: 'Clear logs',
                        ),
                        IconButton(
                          onPressed: () => logger.toggleVisibility(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[_logs.length - 1 - index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 1.0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.formattedMessage,
                            style: TextStyle(
                              color: log.color.withValues(alpha: 0.95),
                              fontSize: 13,
                              fontFamily: 'monospace',
                              height: 1.3,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
