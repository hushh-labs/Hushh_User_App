import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for Google Cloud Vertex AI integration
/// Uses environment variables for secure configuration
class VertexAiConfig {
  // Google Cloud Project Configuration
  static String get projectId =>
      dotenv.env['VERTEX_AI_PROJECT_ID'] ?? 'your-gcp-project-id';

  static String get location =>
      dotenv.env['VERTEX_AI_LOCATION'] ?? 'us-central1';

  static String get model =>
      dotenv.env['VERTEX_AI_MODEL'] ?? 'claude-sonnet-4@20250514';

  // Service Account Configuration
  static String get serviceAccountKey =>
      dotenv.env['VERTEX_AI_SERVICE_ACCOUNT_KEY'] ?? '';

  // API Configuration
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  // Claude Configuration
  static int get maxTokens =>
      int.tryParse(dotenv.env['VERTEX_AI_MAX_TOKENS'] ?? '') ?? 1024;

  static double get temperature =>
      double.tryParse(dotenv.env['VERTEX_AI_TEMPERATURE'] ?? '') ?? 0.7;

  static double get topP =>
      double.tryParse(dotenv.env['VERTEX_AI_TOP_P'] ?? '') ?? 0.95;

  static int get topK =>
      int.tryParse(dotenv.env['VERTEX_AI_TOP_K'] ?? '') ?? 40;

  static const String anthropicVersion = 'vertex-2023-10-16';

  // Context limits
  static int get maxConversationHistory =>
      int.tryParse(dotenv.env['VERTEX_AI_MAX_CONVERSATION_HISTORY'] ?? '') ?? 5;

  static int get maxRecentMessages =>
      int.tryParse(dotenv.env['VERTEX_AI_MAX_RECENT_MESSAGES'] ?? '') ?? 20;

  static int get maxStoredMessages =>
      int.tryParse(dotenv.env['VERTEX_AI_MAX_STORED_MESSAGES'] ?? '') ?? 100;

  // Validation helper
  static bool get isConfigured {
    return projectId.isNotEmpty &&
        projectId != 'your-gcp-project-id' &&
        serviceAccountKey.isNotEmpty;
  }

  // Debug helper (don't log sensitive data in production)
  static Map<String, dynamic> get debugInfo => {
    'projectId': projectId,
    'location': location,
    'model': model,
    'maxTokens': maxTokens,
    'temperature': temperature,
    'isConfigured': isConfigured,
    // Never log the service account key!
  };
}
