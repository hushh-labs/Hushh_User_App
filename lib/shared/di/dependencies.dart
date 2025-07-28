import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:hushh_user_app/shared/constants/enums.dart';

// Mock bloc classes for UI purposes
class MockPdaBloc extends ChangeNotifier {
  final TextEditingController messageController = TextEditingController();
  final List<MockMessage> chatMessages = [];
  final MockUser user = MockUser(id: 'user-123', name: 'User');

  void add(dynamic event) {
    // Mock implementation for UI
  }
}

class MockHomePageBloc extends ChangeNotifier {
  Entity entity = Entity.user;
}

class MockMessage {
  final String id;
  final String text;
  final MockUser author;
  final DateTime createdAt;
  final bool isFromUser;

  MockMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
    required this.isFromUser,
  });
}

class MockUser {
  final String id;
  final String name;

  MockUser({required this.id, required this.name});
}

// Global GetIt instance
final GetIt sl = GetIt.instance;

// Mock dependency injection setup
void setupDependencies() {
  // Register mock blocs
  sl.registerLazySingleton<MockPdaBloc>(() => MockPdaBloc());
  sl.registerLazySingleton<MockHomePageBloc>(() => MockHomePageBloc());
}
