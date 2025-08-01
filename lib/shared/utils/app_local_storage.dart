// Mock user and agent classes for UI purposes
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/enums.dart';

class MockUser {
  final String? avatar;
  final String name;
  final String email;
  final String? phoneNumber;
  final int? userCoins;

  MockUser({
    this.avatar,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.userCoins,
  });
}

class MockAgent {
  final String? agentImage;
  final String name;
  final String email;

  MockAgent({this.agentImage, required this.name, required this.email});
}

class AppLocalStorage {
  // Mock data for UI purposes
  static String? get hushhId => 'mock-user-id-123';

  static MockUser? get user => MockUser(
    avatar: null, // Set to null to show default avatar
    name: 'John Doe',
    email: 'john.doe@example.com',
    userCoins: 1250,
  );

  static MockAgent? get agent => MockAgent(
    agentImage: null, // Set to null to show default avatar
    name: 'Agent Smith',
    email: 'agent.smith@example.com',
  );

  // Guest mode management
  static bool get isGuestMode => false;

  static Future<void> setGuestMode(bool value) async {
    // Mock implementation for UI
  }

  // Login type storage
  static const String _loginTypeKey = 'user_login_type';

  static Future<void> setLoginType(OtpVerificationType loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTypeKey, loginType.name);
  }

  static Future<OtpVerificationType?> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTypeString = prefs.getString(_loginTypeKey);
    if (loginTypeString != null) {
      return OtpVerificationType.values.firstWhere(
        (type) => type.name == loginTypeString,
        orElse: () => OtpVerificationType.phone, // Default to phone
      );
    }
    return null;
  }

  static Future<void> clearLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginTypeKey);
  }
}
