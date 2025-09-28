import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

// Platform-specific imports
import 'razorpay_mobile.dart' if (dart.library.html) 'razorpay_web.dart';
// Secure config service (NO KEYS IN CODE)
import '../../../../core/config/remote_config_service.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import '../../../payment/presentation/bloc/payment_event.dart';
import '../../../payment/presentation/bloc/payment_state.dart';
import '../../../payment/data/models/payment_request_model.dart';
import '../../../payment/data/models/razorpay_request_model.dart';
import '../../../orders/presentation/pages/order_confirmation_page.dart';
import '../../../../shared/core/utils/toast_manager.dart';
import '../../../discover_revamp/presentation/services/cart_presentation_service.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_state.dart';
import '../bloc/checkout_event.dart';
import '../../domain/entities/checkout_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart' as chat;
import '../../../chat/presentation/pages/regular_chat_page.dart';
import '../../../chat/domain/entities/chat_entity.dart';

class PaymentSelectionPage extends StatefulWidget {
  const PaymentSelectionPage({super.key});

  @override
  State<PaymentSelectionPage> createState() => _PaymentSelectionPageState();
}

class _PaymentSelectionPageState extends State<PaymentSelectionPage> {
  Razorpay? _razorpay;
  PaymentBloc? _paymentBloc;
  CheckoutEntity? _checkoutData;

  @override
  void initState() {
    super.initState();
    // Only initialize Razorpay if not in demo mode
    // Demo mode is determined by missing or placeholder secret keys
    _initializeRazorpayIfNeeded();
  }

  void _initializeRazorpayIfNeeded() {
    try {
      // Check if we're in demo mode using secure Remote Config (NO KEYS IN CODE)
      final razorpayKeyId = RemoteConfigService.razorpayKeyId;
      final razorpaySecret = RemoteConfigService.razorpayKeySecret;
      final isDemo = RemoteConfigService.isDemoMode;

      print('Razorpay Key ID: $razorpayKeyId');
      print('Razorpay Secret length: ${razorpaySecret.length}');
      print('Razorpay Demo Mode: $isDemo');

      if (!isDemo) {
        // Initialize for real mode on both mobile and web platforms
        if (kIsWeb) {
          print('Initializing Razorpay for real mode on web');
        } else {
          print('Initializing Razorpay for real mode on mobile');
        }
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      } else {
        print('Razorpay in demo mode - not initializing plugin');
        if (kDebugMode) {
          print(
            '💡 Configure real keys in Firebase Remote Config to enable live payments',
          );
        }
      }
    } catch (e) {
      // If there's any error initializing Razorpay, continue in demo mode
      print('Razorpay initialization failed, continuing in demo mode: $e');
    }
  }

  void _loadCheckoutData(CheckoutBloc bloc) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      bloc.add(LoadCheckoutDataEvent(user.uid));
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentBloc>(
          create: (context) {
            _paymentBloc = GetIt.instance<PaymentBloc>();
            return _paymentBloc!;
          },
        ),
        BlocProvider<CheckoutBloc>(
          create: (context) {
            final bloc = GetIt.instance<CheckoutBloc>();
            // Load checkout data when page initializes
            _loadCheckoutData(bloc);
            return bloc;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return MultiBlocListener(
            listeners: [
              BlocListener<PaymentBloc, PaymentState>(
                listener: (context, state) {
                  if (state is PaymentIntentCreated) {
                    _proceedWithStripePayment(
                      context,
                      state.paymentIntent.clientSecret,
                    );
                  } else if (state is RazorpayPaymentInitiated) {
                    Navigator.of(context).pop(); // Hide loading dialog
                    _openRazorpayCheckout(context, state.paymentOptions);
                  } else if (state is PaymentError) {
                    Navigator.of(context).pop(); // Hide loading dialog
                    _handlePaymentFailure(context, state.message);
                  } else if (state is PaymentSuccess) {
                    Navigator.of(context).pop(); // Hide loading dialog
                    _navigateToSuccessAnimation(context, state);
                  } else if (state is OrderCreated) {
                    // Order created after payment success - clear cart and navigate to bill
                    _clearCartAndNavigateToBill(context, state);
                  }
                },
              ),
              BlocListener<CheckoutBloc, CheckoutState>(
                listener: (context, state) {
                  if (state is CheckoutLoaded ||
                      state is CheckoutFieldUpdated) {
                    _checkoutData = state is CheckoutLoaded
                        ? state.checkoutData
                        : (state as CheckoutFieldUpdated).checkoutData;
                  }
                },
              ),
            ],
            child: _buildScaffold(context),
          );
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Choose Payment Method',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your preferred payment method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            _buildPaymentOption(
              context,
              title: 'Pay with Stripe',
              subtitle: 'Credit/Debit cards, Digital wallets',
              icon: Icons.credit_card,
              iconColor: const Color(0xFF635BFF),
              onTap: () => _handleStripePayment(context),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              context,
              title: 'Pay with Razorpay',
              subtitle: 'UPI, Net Banking, Cards, Wallets',
              icon: Icons.account_balance_wallet,
              iconColor: const Color(0xFF3395FF),
              onTap: () => _handleRazorpayPayment(context),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment information is secure and encrypted',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF666666),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleStripePayment(BuildContext context) async {
    // Get real cart data
    final cartService = CartPresentationService.instance;
    final cart = await cartService.getCurrentCart();

    if (cart.items.isEmpty) {
      _showErrorDialog(context, 'Cart is empty');
      return;
    }

    // Get the PaymentBloc from the context
    final paymentBloc = BlocProvider.of<PaymentBloc>(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Create payment intent with real cart amount
    final paymentRequest = PaymentRequestModel(
      amount: cart.totalPrice, // Real cart total in dollars
      currency: 'usd',
      description: 'Hushh Purchase - ${cart.items.length} items',
      customerId: null, // Optional customer ID
    );

    // Trigger payment intent creation
    paymentBloc.add(CreatePaymentIntentEvent(paymentRequest));
  }

  void _proceedWithStripePayment(
    BuildContext context,
    String clientSecret,
  ) async {
    // Check if this is demo mode (demo client secret)
    if (clientSecret.contains('_secret_demo')) {
      // Demo mode - skip actual Stripe payment sheet and simulate success
      Navigator.of(context).pop(); // Hide loading indicator

      // Show a demo payment sheet simulation
      _showDemoPaymentSheet(context, () {
        // Simulate successful payment after user interaction
        final paymentBloc = BlocProvider.of<PaymentBloc>(context);
        paymentBloc.add(ConfirmPaymentEvent(clientSecret));
      });
      return;
    }

    try {
      // Real Stripe payment flow
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Hushh',
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: null,
          customerId: null,
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: true,
        ),
      );

      Navigator.of(context).pop(); // Hide loading indicator
      await Stripe.instance.presentPaymentSheet();

      final paymentBloc = BlocProvider.of<PaymentBloc>(context);
      paymentBloc.add(ConfirmPaymentEvent(clientSecret));
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog(context, e.toString());
    }
  }

  void _handleRazorpayPayment(BuildContext context) async {
    // Get real cart data
    final cartService = CartPresentationService.instance;
    final cart = await cartService.getCurrentCart();

    if (cart.items.isEmpty) {
      _showErrorDialog(context, 'Cart is empty');
      return;
    }

    // Get the PaymentBloc from the context
    final paymentBloc = BlocProvider.of<PaymentBloc>(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Create Razorpay payment request with real cart amount (convert USD to INR roughly)
    final amountInINR = cart.totalPrice * 83; // Rough USD to INR conversion
    final razorpayRequest = RazorpayRequestModel(
      amount: amountInINR, // Amount in rupees
      currency: 'INR',
      description: 'Hushh Purchase - ${cart.items.length} items',
      customerId: 'customer_${DateTime.now().millisecondsSinceEpoch}',
      customerEmail:
          'demo@example.com', // We'll get this from checkout data later
      customerPhone: '+919876543210', // We'll get this from checkout data later
    );

    // Trigger Razorpay payment initiation
    paymentBloc.add(InitiateRazorpayPaymentEvent(razorpayRequest));
  }

  void _openRazorpayCheckout(
    BuildContext context,
    Map<String, dynamic> options,
  ) {
    print('Opening Razorpay checkout with options: $options');

    // Check if this is true demo mode (only show custom demo for placeholder keys)
    // Test keys (rzp_test_) should use real Razorpay plugin in test mode
    if (options.containsKey('demo_mode') &&
        options['demo_mode'] == true &&
        options['key'] == 'rzp_demo_key') {
      print('Demo mode detected - showing demo payment sheet');
      // Only show demo payment sheet for actual demo keys, not test keys
      _showDemoRazorpaySheet(context, () {
        // Simulate successful payment
        _handleRazorpaySuccess(
          PaymentSuccessResponse(
            'demo_payment_${DateTime.now().millisecondsSinceEpoch}',
            options['order_id'] ?? 'demo_order',
            'demo_signature_${DateTime.now().millisecondsSinceEpoch}',
            null, // Additional data field
          ),
        );
      });
      return;
    }

    // Real Razorpay checkout for both mobile and web
    if (kIsWeb) {
      print('Web platform - using Razorpay JavaScript SDK');
    } else {
      print('Mobile platform - using Razorpay Flutter plugin');
    }

    print('Real Razorpay mode - checking instance: ${_razorpay != null}');
    if (_razorpay == null) {
      print('Razorpay instance is null, showing error');
      _showErrorDialog(context, 'Razorpay not initialized properly');
      return;
    }

    try {
      print('Calling _razorpay.open() with options');
      _razorpay!.open(options);
      print('_razorpay.open() called successfully');
    } catch (e) {
      print('Error calling _razorpay.open(): $e');
      _showErrorDialog(context, 'Failed to open Razorpay checkout: $e');
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    // Get real cart amount for processing
    final cartService = CartPresentationService.instance;
    final cart = await cartService.getCurrentCart();
    final amountInINR = cart.totalPrice * 83; // Convert USD to INR

    // Payment successful - process it through the bloc
    if (_paymentBloc != null) {
      _paymentBloc!.add(
        ProcessRazorpayPaymentEvent(
          paymentResponse: {
            'razorpay_payment_id': response.paymentId,
            'razorpay_order_id': response.orderId,
            'razorpay_signature': response.signature,
          },
          amount: amountInINR, // Real amount in rupees
          currency: 'INR',
        ),
      );
    } else {
      _showErrorDialog(context, 'Payment bloc not available');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    _showErrorDialog(context, 'Razorpay Error: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showErrorDialog(
      context,
      'External wallet selected: ${response.walletName}',
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Payment Successful',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Your payment has been processed successfully!',
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1D1D1F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDemoPaymentSheet(BuildContext context, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.credit_card, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Demo Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This is a demo payment simulation.',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
              SizedBox(height: 16),
              Text(
                'Amount: \$10.00',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Payment Method: Demo Card',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDemoRazorpaySheet(BuildContext context, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Demo Razorpay Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This is a demo Razorpay payment simulation.',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
              SizedBox(height: 16),
              Text(
                'Amount: ₹10.00',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Payment Methods: UPI, Cards, Net Banking, Wallets',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Payment Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Payment could not be processed. Please try again.\n\nError: $error',
            style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1D1D1F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handlePaymentFailure(BuildContext context, String error) {
    // Navigate back to discover page and show error toast
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Show error toast
    ToastManager.showToast(context, 'Payment Failed', type: ToastType.error);
  }

  void _navigateToSuccessAnimation(
    BuildContext context,
    PaymentSuccess state,
  ) async {
    // Get real cart and checkout data
    final cartService = CartPresentationService.instance;
    final cart = await cartService.getCurrentCart();

    // Navigate to the animated success page (reusing OrderConfirmationPage)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrderConfirmationPage(
          orderId: 'pending', // Will be updated when order is created
          paymentId: state.paymentId,
          amount: state.amount,
          currency: state.currency,
          paymentMethod: state.paymentMethod,
        ),
      ),
    );

    // Trigger order creation after navigating to animation with real data
    if (_paymentBloc != null) {
      _paymentBloc!.add(
        CreateOrderAfterPaymentEvent(
          paymentId: state.paymentId,
          paymentMethod: state.paymentMethod,
          amount: state.amount,
          currency: state.currency,
          additionalData: {
            'agentId': cart.currentAgentId ?? 'unknown_agent',
            'agentName': cart.currentAgentName ?? 'Unknown Agent',
            'items': cart.items
                .map(
                  (item) => {
                    'productId': item.productId,
                    'productName': item.productName,
                    'price': item.price,
                    'quantity': item.quantity,
                    'imageUrl': item.imageUrl,
                    'description': item.description,
                  },
                )
                .toList(),
            // Use real checkout data from CheckoutBloc following clean architecture
            'street': _checkoutData?.addressLine1 ?? 'Address not provided',
            'city': _checkoutData?.city ?? 'City not provided',
            'state': _checkoutData?.state ?? 'State not provided',
            'postalCode': _checkoutData?.pincode ?? 'Pincode not provided',
            'country': _checkoutData?.country ?? 'Country not provided',
            'fullName': _checkoutData?.fullName ?? 'Name not provided',
            'phoneNumber': _checkoutData?.phoneNumber ?? 'Phone not provided',
          },
        ),
      );
    }
  }

  void _clearCartAndNavigateToBill(
    BuildContext context,
    OrderCreated state,
  ) async {
    // Clear the cart after successful order creation
    final cartService = CartPresentationService.instance;
    final cart = await cartService.getCurrentCart();

    // Create automatic chat with agent before clearing cart
    await _createAutomaticOrderChat(context, state, cart);

    // Clear the cart after chat creation
    await cartService.clearCart();

    print('Cart cleared after successful order: ${state.orderId}');

    // Navigate to bill/receipt page
    _navigateToBill(context, state);
  }

  Future<void> _createAutomaticOrderChat(
    BuildContext context,
    OrderCreated orderState,
    dynamic cart,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('User not logged in, skipping chat creation');
        return;
      }

      final agentId = cart.currentAgentId;
      if (agentId == null || agentId.isEmpty) {
        print('Agent ID not available, skipping chat creation');
        return;
      }

      // Create chat ID by combining user IDs
      final participantIds = [currentUser.uid, agentId]..sort();
      final chatId = participantIds.join('_');

      // Create chat bloc and handle chat opening (works for both new and existing chats)
      final chatBloc = chat.ChatBloc();

      // Open existing chat or create new one - OpenChatEvent handles both scenarios
      chatBloc.add(chat.OpenChatEvent(chatId));

      // Send automatic order confirmation message to the chat (existing or new)
      await _sendOrderConfirmationMessage(chatBloc, chatId, orderState, cart);

      print('Order confirmation sent to chat (existing or new): $chatId');
    } catch (e) {
      print('Error sending order confirmation to chat: $e');
      // Don't throw error as this is not critical to the order process
    }
  }

  Future<void> _sendOrderConfirmationMessage(
    chat.ChatBloc chatBloc,
    String chatId,
    OrderCreated orderState,
    dynamic cart,
  ) async {
    try {
      // Format currency display
      final currencySymbol = orderState.currency == 'INR' ? '₹' : '\$';
      final formattedAmount = orderState.amount.toStringAsFixed(2);

      // Create order items list with correct currency conversion
      final itemsList = cart.items
          .map((item) {
            // Convert price to correct currency if needed
            double itemPrice = item.price;
            if (orderState.currency == 'INR') {
              // Convert USD to INR (same conversion rate as used in payment)
              itemPrice = item.price * 83;
            }
            return '• ${item.productName} - Qty: ${item.quantity} - ${currencySymbol}${itemPrice.toStringAsFixed(2)}';
          })
          .join('\n');

      // Get delivery address
      final deliveryAddress = _checkoutData != null
          ? '''
Delivery Address:
${_checkoutData!.fullName ?? 'Name not provided'}
${_checkoutData!.addressLine1 ?? 'Address not provided'}
${_checkoutData!.city ?? 'City not provided'}, ${_checkoutData!.state ?? 'State not provided'}
${_checkoutData!.pincode ?? 'Pincode not provided'}
${_checkoutData!.country ?? 'Country not provided'}
Phone: ${_checkoutData!.phoneNumber ?? 'Phone not provided'}'''
          : 'Delivery address not available';

      // Create comprehensive order confirmation message without emojis
      final orderMessage =
          '''ORDER PLACED SUCCESSFULLY!

Thank you for your purchase! Your order has been confirmed and payment processed.

ORDER DETAILS:
Order ID: ${orderState.orderId}
Payment ID: ${orderState.paymentId}
Total Amount: $currencySymbol$formattedAmount
Payment Method: ${orderState.paymentMethod.toUpperCase()}
Currency: ${orderState.currency}

ITEMS ORDERED:
$itemsList

$deliveryAddress

PAYMENT STATUS: CONFIRMED
Your payment has been successfully processed and your order is now being prepared for shipment.

We'll keep you updated on your order status. If you have any questions or need assistance, feel free to reach out!

Thanks for choosing us!''';

      // Add a small delay to ensure chat is initialized
      await Future.delayed(const Duration(milliseconds: 1000));

      // Send the order confirmation message
      chatBloc.add(
        chat.SendMessageEvent(
          chatId: chatId,
          message: orderMessage,
          isBot: false,
        ),
      );

      print('Order confirmation message sent to chat');
    } catch (e) {
      print('Error sending order confirmation message: $e');
    }
  }

  void _navigateToBill(BuildContext context, OrderCreated state) {
    // TODO: Navigate to bill/receipt page
    // For now, we'll update the current page or show a bill dialog
    print('Order created: ${state.orderId}');

    // You can create a separate BillPage and navigate to it here
    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(
    //     builder: (context) => BillPage(
    //       orderId: state.orderId,
    //       paymentId: state.paymentId,
    //       amount: state.amount,
    //       currency: state.currency,
    //       paymentMethod: state.paymentMethod,
    //     ),
    //   ),
    // );
  }
}
