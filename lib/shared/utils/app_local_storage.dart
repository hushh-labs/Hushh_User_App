// Mock user and agent classes for UI purposes
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
}
