import '../../../../core/config/remote_config_service.dart';

/// Configuration for Google Cloud Vertex AI integration
/// Uses environment variables for secure configuration
class VertexAiConfig {
  // Google Cloud Project Configuration
  static String get projectId => RemoteConfigService.vertexAiProjectId;

  static String get location => RemoteConfigService.vertexAiLocation;

  static String get model => RemoteConfigService.vertexAiModel;

  // Service Account Configuration
  static String get serviceAccountKey =>
      RemoteConfigService.vertexAiServiceAccountKey;

  // API Configuration
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  // Claude Configuration
  static int get maxTokens =>
      int.tryParse(RemoteConfigService.vertexAiMaxTokens) ?? 1024;

  static double get temperature =>
      double.tryParse(RemoteConfigService.vertexAiTemperature) ?? 0.7;

  static double get topP =>
      double.tryParse(RemoteConfigService.vertexAiTopP) ?? 0.95;

  static int get topK => int.tryParse(RemoteConfigService.vertexAiTopK) ?? 40;

  static const String anthropicVersion = 'vertex-2023-10-16';

  // Context limits
  static int get maxConversationHistory =>
      int.tryParse(RemoteConfigService.vertexAiMaxConversationHistory) ?? 5;

  static int get maxRecentMessages =>
      int.tryParse(RemoteConfigService.vertexAiMaxRecentMessages) ?? 20;

  static int get maxStoredMessages =>
      int.tryParse(RemoteConfigService.vertexAiMaxStoredMessages) ?? 100;

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
