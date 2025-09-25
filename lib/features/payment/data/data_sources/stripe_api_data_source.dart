import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_request_model.dart';
import '../models/payment_intent_model.dart';

abstract class StripeApiDataSource {
  Future<PaymentIntentModel> createPaymentIntent(PaymentRequestModel request);
  Future<String> getPaymentStatus(String paymentIntentId);
}

class StripeApiDataSourceImpl implements StripeApiDataSource {
  static const String _baseUrl = 'https://api.stripe.com/v1';
  final String _secretKey;
  final http.Client httpClient;

  StripeApiDataSourceImpl({required String secretKey, required this.httpClient})
    : _secretKey = secretKey;

  @override
  Future<PaymentIntentModel> createPaymentIntent(
    PaymentRequestModel request,
  ) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: _formatRequestBody(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PaymentIntentModel.fromJson(data);
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw StripeApiException(
          message: errorData['error']['message'] ?? 'Unknown error',
          code: errorData['error']['code'],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is StripeApiException) rethrow;
      throw StripeApiException(
        message: 'Failed to create payment intent: $e',
        code: 'network_error',
        statusCode: 0,
      );
    }
  }

  @override
  Future<String> getPaymentStatus(String paymentIntentId) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['status'] as String;
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw StripeApiException(
          message: errorData['error']['message'] ?? 'Unknown error',
          code: errorData['error']['code'],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is StripeApiException) rethrow;
      throw StripeApiException(
        message: 'Failed to get payment status: $e',
        code: 'network_error',
        statusCode: 0,
      );
    }
  }

  String _formatRequestBody(Map<String, dynamic> data) {
    return data.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}',
        )
        .join('&');
  }
}

class StripeApiException implements Exception {
  final String message;
  final String? code;
  final int statusCode;

  StripeApiException({
    required this.message,
    this.code,
    required this.statusCode,
  });

  @override
  String toString() =>
      'StripeApiException: $message (code: $code, status: $statusCode)';
}
