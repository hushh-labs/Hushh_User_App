# Routing Setup with GoRouter

This directory contains the routing configuration using GoRouter for clean navigation throughout the app.

## Structure

```
routing/
├── app_router.dart          # Main router configuration
├── route_paths.dart         # Route paths and names constants
├── auth_guard.dart          # Authentication route guard
├── navigation_service.dart   # Navigation service abstract class
├── navigation_service_impl.dart # Navigation service implementation
└── navigation_helper.dart    # Helper methods for easy navigation
```

## Features

### 1. **Route Management**
- Centralized route definitions in `route_paths.dart`
- Easy to add new routes and maintain consistency
- Named routes for type-safe navigation

### 2. **Authentication Guard**
- Automatic redirection based on authentication state
- Protected routes for authenticated users
- Public routes for unauthenticated users

### 3. **Navigation Service**
- Abstract navigation interface for dependency injection
- GoRouter implementation
- Easy to test and mock

### 4. **Navigation Helper**
- Static methods for common navigation actions
- Type-safe navigation with route names
- Easy to use from anywhere in the app

## Usage

### Basic Navigation

```dart
// Navigate to a route
NavigationHelper.goToHome(context);

// Navigate with arguments
NavigationHelper.goToWithArguments(context, RouteNames.profile, userData);

// Go back
NavigationHelper.goBack(context);
```

### Using GoRouter Directly

```dart
// Navigate to named route
context.goNamed(RouteNames.home);

// Navigate to path
context.go(RoutePaths.home);

// Push route (keeps previous route in stack)
context.pushNamed(RouteNames.profile);

// Replace current route
context.pushReplacementNamed(RouteNames.settings);
```

### Adding New Routes

1. **Add route constants** in `route_paths.dart`:
   ```dart
   class RoutePaths {
     static const String newFeature = '/new-feature';
   }
   
   class RouteNames {
     static const String newFeature = 'new-feature';
   }
   ```

2. **Add route to router** in `app_router.dart`:
   ```dart
   GoRoute(
     path: RoutePaths.newFeature,
     name: RouteNames.newFeature,
     builder: (context, state) => const NewFeaturePage(),
   ),
   ```

3. **Add navigation helper** in `navigation_helper.dart`:
   ```dart
   static void goToNewFeature(BuildContext context) {
     context.goNamed(RouteNames.newFeature);
   }
   ```

## Route Protection

The `AuthGuard` automatically handles route protection:

- **Unauthenticated users** trying to access protected routes → redirected to login
- **Authenticated users** trying to access auth routes → redirected to home
- **Public routes** accessible to everyone

## Error Handling

- Custom error page for 404 routes
- Graceful handling of navigation errors
- Debug information for development

## Testing

The navigation service can be easily mocked for testing:

```dart
class MockNavigationService implements NavigationService {
  @override
  void navigateTo(String routeName, {Object? arguments}) {
    // Mock implementation
  }
  // ... other methods
}
```

## Best Practices

1. **Always use named routes** for type safety
2. **Use NavigationHelper** for common navigation patterns
3. **Keep route paths centralized** in `route_paths.dart`
4. **Test navigation** with mocked navigation service
5. **Use route guards** for authentication and authorization
6. **Handle navigation errors** gracefully

## Dependencies

- `go_router`: For routing functionality
- `flutter_bloc`: For state management integration
- `firebase_auth`: For authentication state 