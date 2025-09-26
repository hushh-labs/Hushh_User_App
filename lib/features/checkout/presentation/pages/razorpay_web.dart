// Web implementation using Razorpay JavaScript SDK
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class Razorpay {
  // Constants that match the mobile plugin
  static const String EVENT_PAYMENT_SUCCESS = 'payment.success';
  static const String EVENT_PAYMENT_ERROR = 'payment.error';
  static const String EVENT_EXTERNAL_WALLET = 'payment.external_wallet';

  final Map<String, Function> _handlers = {};

  // Constructor
  Razorpay();

  // Event listeners - store handlers for later use
  void on(String event, Function handler) {
    _handlers[event] = handler;
    if (kDebugMode) {
      print('Razorpay web: Registered handler for event: $event');
    }
  }

  // Open payment using Razorpay JavaScript SDK - Simplified Direct Approach
  void open(Map<String, dynamic> options) {
    if (kDebugMode) {
      print('Razorpay web: Opening checkout with options: $options');
      print('Razorpay web: Key value: ${options['key']}');
    }

    try {
      // Check if Razorpay is available
      if (js.context['Razorpay'] == null) {
        throw Exception('Razorpay JavaScript SDK not loaded');
      }

      // Direct JavaScript execution approach
      final script =
          '''
        console.log("Creating Razorpay with key: ${options['key']}");
        
        var razorpayOptions = {
          "key": "${options['key']}",
          "amount": ${options['amount']},
          "currency": "${options['currency'] ?? 'INR'}",
          "name": "${options['name'] ?? 'Hushh'}",
          "description": "${options['description'] ?? ''}",
          "order_id": "${options['order_id'] ?? ''}",
          "handler": function(response) {
            console.log("Payment successful", response);
            window.flutterPaymentSuccess = response;
          },
          "modal": {
            "ondismiss": function() {
              console.log("Payment dismissed");
              window.flutterPaymentError = "dismissed";
            }
          },
          "theme": {
            "color": "#A342FF"
          }
        };
        
        if ("${options['prefill']}" !== "null" && "${options['prefill']}" !== "") {
          razorpayOptions.prefill = {
            "name": "${options['prefill']?['name'] ?? ''}",
            "email": "${options['prefill']?['email'] ?? ''}",
            "contact": "${options['prefill']?['contact'] ?? ''}"
          };
        }
        
        console.log("Razorpay options:", razorpayOptions);
        
        var rzp = new Razorpay(razorpayOptions);
        console.log("Razorpay instance created:", rzp);
        
        rzp.open();
        console.log("Razorpay open() called");
      ''';

      if (kDebugMode) {
        print('Razorpay web: Executing JavaScript:\n$script');
      }

      // Execute the JavaScript directly
      js.context.callMethod('eval', [script]);

      // Set up listeners for responses
      _setupResponseListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Razorpay web: Error opening checkout: $e');
      }

      if (_handlers.containsKey(EVENT_PAYMENT_ERROR)) {
        final errorResponse = PaymentFailureResponse(
          500,
          'Failed to open Razorpay checkout: $e',
          null,
        );
        _handlers[EVENT_PAYMENT_ERROR]!(errorResponse);
      }
    }
  }

  // Set up listeners for JavaScript responses
  void _setupResponseListeners() {
    // Check for success response
    js.context['checkPaymentSuccess'] = js.allowInterop(() {
      final response = js.context['flutterPaymentSuccess'];
      if (response != null) {
        js.context['flutterPaymentSuccess'] = null; // Clear it

        if (_handlers.containsKey(EVENT_PAYMENT_SUCCESS)) {
          final successResponse = PaymentSuccessResponse(
            response['razorpay_payment_id'] ?? '',
            response['razorpay_order_id'],
            response['razorpay_signature'],
            {},
          );
          _handlers[EVENT_PAYMENT_SUCCESS]!(successResponse);
        }
      }
    });

    // Check for error response
    js.context['checkPaymentError'] = js.allowInterop(() {
      final error = js.context['flutterPaymentError'];
      if (error != null) {
        js.context['flutterPaymentError'] = null; // Clear it

        if (_handlers.containsKey(EVENT_PAYMENT_ERROR)) {
          final errorResponse = PaymentFailureResponse(
            1,
            'Payment cancelled or failed: $error',
            null,
          );
          _handlers[EVENT_PAYMENT_ERROR]!(errorResponse);
        }
      }
    });

    // Start polling for responses
    js.context.callMethod('eval', [
      '''
      function pollForResponses() {
        if (window.flutterPaymentSuccess) {
          window.checkPaymentSuccess();
        }
        if (window.flutterPaymentError) {
          window.checkPaymentError();
        }
        setTimeout(pollForResponses, 100);
      }
      pollForResponses();
    ''',
    ]);
  }

  // Clear - cleanup method
  void clear() {
    _handlers.clear();
    if (kDebugMode) {
      print('Razorpay web: Cleared handlers');
    }
  }
}

// Response classes that match the mobile plugin
class PaymentSuccessResponse {
  final String paymentId;
  final String? orderId;
  final String? signature;
  final Map<String, dynamic>? data;

  PaymentSuccessResponse(
    this.paymentId,
    this.orderId,
    this.signature,
    this.data,
  );
}

class PaymentFailureResponse {
  final int code;
  final String message;
  final Map<String, dynamic>? data;

  PaymentFailureResponse(this.code, this.message, this.data);
}

class ExternalWalletResponse {
  final String walletName;
  final Map<String, dynamic>? data;

  ExternalWalletResponse(this.walletName, this.data);
}
