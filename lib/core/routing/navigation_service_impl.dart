// Navigation service implementation with GoRouter
import 'package:go_router/go_router.dart';
import 'navigation_service.dart';

class NavigationServiceImpl implements NavigationService {
  final GoRouter _router;

  NavigationServiceImpl(this._router);

  @override
  void navigateTo(String routeName, {Object? arguments}) {
    _router.pushNamed(routeName, extra: arguments);
  }

  @override
  void navigateToReplacement(String routeName, {Object? arguments}) {
    _router.pushReplacementNamed(routeName, extra: arguments);
  }

  @override
  void navigateToAndClear(String routeName, {Object? arguments}) {
    _router.goNamed(routeName, extra: arguments);
  }

  @override
  void goBack() {
    if (canGoBack()) {
      _router.pop();
    }
  }

  @override
  bool canGoBack() {
    return _router.canPop();
  }

  @override
  String? getCurrentRoute() {
    // GoRouter doesn't have a direct location getter
    // We'll return null for now, you can implement this based on your needs
    return null;
  }

  // Additional GoRouter specific methods
  void goTo(String path) {
    _router.go(path);
  }

  void push(String path) {
    _router.push(path);
  }

  void pushReplacement(String path) {
    _router.pushReplacement(path);
  }
}
