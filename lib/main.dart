import 'package:flutter/foundation.dart';
import 'app.dart';
import 'core/services/logger_service.dart';

void main() async {
  // Override debugPrint function to capture all prints
  debugPrint = capturePrint;

  await mainApp();
}
