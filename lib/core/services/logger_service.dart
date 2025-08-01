import 'dart:async';
import 'package:flutter/material.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final List<LogEntry> _logs = [];
  final StreamController<List<LogEntry>> _logsController =
      StreamController<List<LogEntry>>.broadcast();

  bool _isVisible = false;
  final StreamController<bool> _visibilityController =
      StreamController<bool>.broadcast();

  Stream<List<LogEntry>> get logsStream => _logsController.stream;
  Stream<bool> get visibilityStream => _visibilityController.stream;
  bool get isVisible => _isVisible;
  List<LogEntry> get logs => List.from(_logs);

  void log(String message, {LogLevel level = LogLevel.info, String? tag}) {
    final entry = LogEntry(
      message: message,
      level: level,
      tag: tag,
      timestamp: DateTime.now(),
    );

    _logs.add(entry);

    // Keep only last 1000 logs to prevent memory issues
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }

    _logsController.add(List.from(_logs));
  }

  void toggleVisibility() {
    _isVisible = !_isVisible;
    _visibilityController.add(_isVisible);
  }

  void clear() {
    _logs.clear();
    _logsController.add([]);
  }

  void dispose() {
    _logsController.close();
    _visibilityController.close();
  }
}

class LogEntry {
  final String message;
  final LogLevel level;
  final String? tag;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.level,
    this.tag,
    required this.timestamp,
  });

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  String get formattedMessage {
    final tagText = tag != null ? '[$tag]' : '';
    return '$formattedTime $tagText $message';
  }

  Color get color {
    switch (level) {
      case LogLevel.debug:
        return Colors.cyan;
      case LogLevel.info:
        return Colors.white;
      case LogLevel.warning:
        return Colors.yellow;
      case LogLevel.error:
        return Colors.red;
    }
  }
}

enum LogLevel { debug, info, warning, error }

// Global logger instance
final logger = LoggerService();

// Function to capture prints (will be used to override debugPrint)
void capturePrint(String? message, {int? wrapWidth}) {
  if (message != null) {
    logger.log(message, level: LogLevel.info, tag: 'PRINT');
  }
  // Call original print - ignore linter warning for this specific case
  // ignore: avoid_print
  print(message);
}
