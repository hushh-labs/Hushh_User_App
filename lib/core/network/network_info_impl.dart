// Network info implementation - Web compatible
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'network_info.dart';

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      if (kIsWeb) {
        // Web-compatible network check using HTTP request
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 5));
        return response.statusCode == 200;
      } else {
        // Mobile platforms - use HTTP request for consistency
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 5));
        return response.statusCode == 200;
      }
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      // Catch any other exceptions (TimeoutException, etc.)
      return false;
    }
  }
}
