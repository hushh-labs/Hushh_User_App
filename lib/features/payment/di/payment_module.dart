import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../data/data_sources/stripe_api_data_source.dart';
import '../data/data_sources/razorpay_api_data_source.dart';
// Secure Remote Config service (NO KEYS IN CODE)
import '../../../core/config/remote_config_service.dart';
import '../data/repository_impl/payment_repository_impl.dart';
import '../domain/repositories/payment_repository.dart';
import '../domain/usecases/create_payment_intent.dart';
import '../domain/usecases/confirm_payment.dart';
import '../domain/usecases/initiate_razorpay_payment.dart';
import '../domain/usecases/process_razorpay_payment.dart';
import '../../orders/data/data_sources/orders_firebase_data_source.dart';
import '../../orders/data/repository_impl/order_repository_impl.dart';
import '../../orders/domain/repositories/order_repository.dart';
import '../../orders/domain/usecases/create_order.dart';
import '../presentation/bloc/payment_bloc.dart';

class PaymentModule {
  static void registerDependencies() {
    final getIt = GetIt.instance;

    // Load payment keys from secure Remote Config (NO KEYS IN CODE)
    final stripeSecretKey = RemoteConfigService.stripeSecretKey;
    final stripePublishableKey = RemoteConfigService.stripePublishableKey;
    final razorpayKeyId = RemoteConfigService.razorpayKeyId;

    // Check demo mode status
    final isStripeDemoMode = RemoteConfigService.isStripeDemoMode;
    final isRazorpayDemoMode = RemoteConfigService.isDemoMode;

    // Check if we have at least one payment method configured (or demo mode enabled)
    final hasStripe = stripePublishableKey.isNotEmpty || isStripeDemoMode;
    final hasRazorpay = razorpayKeyId.isNotEmpty || isRazorpayDemoMode;

    if (!hasStripe && !hasRazorpay) {
      print('⚠️ [PAYMENT] No payment providers configured, using demo mode');
      print(
        '💡 [PAYMENT] Configure keys in Firebase Remote Config for production',
      );
      // Allow demo mode to continue - don't throw exception
    }

    // Data Sources - only register if keys are available
    if (hasStripe) {
      getIt.registerLazySingleton<StripeApiDataSource>(
        () => StripeApiDataSourceImpl(
          secretKey: stripeSecretKey.isEmpty ? 'test_key' : stripeSecretKey,
          httpClient: getIt<http.Client>(),
        ),
      );
    }

    if (hasRazorpay) {
      getIt.registerLazySingleton<RazorpayApiDataSource>(
        () => RazorpayApiDataSourceImpl(keyId: razorpayKeyId),
      );
    }

    // Repositories
    getIt.registerLazySingleton<PaymentRepository>(
      () => PaymentRepositoryImpl(
        stripeApiDataSource: hasStripe ? getIt<StripeApiDataSource>() : null,
        razorpayApiDataSource: hasRazorpay
            ? getIt<RazorpayApiDataSource>()
            : null,
      ),
    );

    // Use Cases - Stripe
    getIt.registerLazySingleton<CreatePaymentIntent>(
      () => CreatePaymentIntent(getIt<PaymentRepository>()),
    );
    getIt.registerLazySingleton<ConfirmPayment>(
      () => ConfirmPayment(getIt<PaymentRepository>()),
    );

    // Use Cases - Razorpay
    getIt.registerLazySingleton<InitiateRazorpayPayment>(
      () => InitiateRazorpayPayment(getIt<PaymentRepository>()),
    );
    getIt.registerLazySingleton<ProcessRazorpayPayment>(
      () => ProcessRazorpayPayment(getIt<PaymentRepository>()),
    );

    // Orders Data Sources
    getIt.registerLazySingleton<OrdersFirebaseDataSource>(
      () => OrdersFirebaseDataSourceImpl(),
    );

    // Orders Repositories
    getIt.registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(getIt<OrdersFirebaseDataSource>()),
    );

    // Orders Use Cases
    getIt.registerLazySingleton<CreateOrder>(
      () => CreateOrder(getIt<OrderRepository>()),
    );

    // BLoC
    getIt.registerFactory<PaymentBloc>(
      () => PaymentBloc(
        createPaymentIntent: getIt<CreatePaymentIntent>(),
        confirmPayment: getIt<ConfirmPayment>(),
        initiateRazorpayPayment: getIt<InitiateRazorpayPayment>(),
        processRazorpayPayment: getIt<ProcessRazorpayPayment>(),
        createOrder: getIt<CreateOrder>(),
      ),
    );
  }
}
