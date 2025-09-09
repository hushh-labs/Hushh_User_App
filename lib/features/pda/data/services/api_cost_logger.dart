import 'package:flutter/foundation.dart';

/// Simple service to calculate and log API costs for Vertex AI and Gemini usage
class ApiCostLogger {
  // Vertex AI Claude 3.5 Sonnet pricing (as of 2024)
  // Input tokens: $3.00 per 1M tokens
  // Output tokens: $15.00 per 1M tokens
  static const double _vertexAiInputCostPer1MTokens = 3.00;
  static const double _vertexAiOutputCostPer1MTokens = 15.00;

  // Gemini 1.5 Pro API pricing (as of 2024)
  // Input tokens: $1.25 per 1M tokens (for Gemini 1.5 Pro)
  // Output tokens: $5.00 per 1M tokens (for Gemini 1.5 Pro)
  static const double _geminiInputCostPer1MTokens = 1.25;
  static const double _geminiOutputCostPer1MTokens = 5.00;

  /// Calculate cost for Vertex AI Claude usage
  static double calculateVertexAiCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    final inputCost = (inputTokens / 1000000) * _vertexAiInputCostPer1MTokens;
    final outputCost =
        (outputTokens / 1000000) * _vertexAiOutputCostPer1MTokens;
    return inputCost + outputCost;
  }

  /// Calculate cost for Gemini API usage
  static double calculateGeminiCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    final inputCost = (inputTokens / 1000000) * _geminiInputCostPer1MTokens;
    final outputCost = (outputTokens / 1000000) * _geminiOutputCostPer1MTokens;
    return inputCost + outputCost;
  }

  /// Estimate input tokens from text (rough approximation: 1 token ≈ 4 characters)
  static int estimateTokensFromText(String text) {
    return (text.length / 4).ceil();
  }

  /// Estimate tokens from base64 data (for images/files)
  static int estimateTokensFromBase64(String base64Data, String mimeType) {
    // Different file types have different token costs
    final sizeInBytes = (base64Data.length * 3 / 4)
        .ceil(); // Approximate original size

    if (mimeType.startsWith('image/')) {
      // Images: roughly 85 tokens per image + size factor
      return 85 + (sizeInBytes / 1024).ceil(); // Base cost + size factor
    } else if (mimeType.contains('pdf')) {
      // PDFs: roughly 1 token per 4 characters of extracted text
      // Estimate based on file size (very rough approximation)
      return (sizeInBytes / 2).ceil(); // Rough estimate for PDF content
    } else {
      // Other files: estimate based on size
      return (sizeInBytes / 4).ceil();
    }
  }

  /// Log Vertex AI API usage and cost
  static void logVertexAiCost({
    required String prompt,
    required String response,
    required List<Map<String, dynamic>> documentFiles,
  }) {
    try {
      // Calculate input tokens
      int inputTokens = estimateTokensFromText(prompt);

      // Add tokens for document files
      for (final file in documentFiles) {
        if (file['type'] == 'image' && file['source'] != null) {
          final source = file['source'] as Map<String, dynamic>;
          final base64Data = source['data'] as String? ?? '';
          final mimeType = source['media_type'] as String? ?? '';
          inputTokens += estimateTokensFromBase64(base64Data, mimeType);
        }
      }

      // Calculate output tokens
      final outputTokens = estimateTokensFromText(response);

      // Calculate cost
      final cost = calculateVertexAiCost(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );

      final inputCost = (inputTokens / 1000000) * _vertexAiInputCostPer1MTokens;
      final outputCost =
          (outputTokens / 1000000) * _vertexAiOutputCostPer1MTokens;

      // Log the cost information
      debugPrint('💰 [VERTEX AI COST] ===== COST BREAKDOWN =====');
      debugPrint('💰 [VERTEX AI COST] Model: Claude 3.5 Sonnet');
      debugPrint('💰 [VERTEX AI COST] Input Tokens: $inputTokens');
      debugPrint('💰 [VERTEX AI COST] Output Tokens: $outputTokens');
      debugPrint(
        '💰 [VERTEX AI COST] Total Tokens: ${inputTokens + outputTokens}',
      );
      debugPrint(
        '💰 [VERTEX AI COST] Input Cost: \$${inputCost.toStringAsFixed(6)}',
      );
      debugPrint(
        '💰 [VERTEX AI COST] Output Cost: \$${outputCost.toStringAsFixed(6)}',
      );
      debugPrint(
        '💰 [VERTEX AI COST] TOTAL COST: \$${cost.toStringAsFixed(6)}',
      );
      debugPrint('💰 [VERTEX AI COST] Document Files: ${documentFiles.length}');
      debugPrint('💰 [VERTEX AI COST] Prompt Length: ${prompt.length} chars');
      debugPrint(
        '💰 [VERTEX AI COST] Response Length: ${response.length} chars',
      );
      debugPrint('💰 [VERTEX AI COST] ===== END COST BREAKDOWN =====');
    } catch (e) {
      debugPrint('❌ [VERTEX AI COST] Error calculating cost: $e');
    }
  }

  /// Log Gemini API usage and cost
  static void logGeminiCost({
    required String prompt,
    required String response,
    required String base64Data,
    required String mimeType,
    required String fileName,
  }) {
    try {
      // Calculate input tokens
      int inputTokens = estimateTokensFromText(prompt);
      inputTokens += estimateTokensFromBase64(base64Data, mimeType);

      // Calculate output tokens
      final outputTokens = estimateTokensFromText(response);

      // Calculate cost
      final cost = calculateGeminiCost(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );

      final inputCost = (inputTokens / 1000000) * _geminiInputCostPer1MTokens;
      final outputCost =
          (outputTokens / 1000000) * _geminiOutputCostPer1MTokens;

      // Log the cost information
      debugPrint('💰 [GEMINI COST] ===== COST BREAKDOWN =====');
      debugPrint('💰 [GEMINI COST] Model: Gemini 1.5 Pro');
      debugPrint('💰 [GEMINI COST] File: $fileName ($mimeType)');
      debugPrint('💰 [GEMINI COST] Input Tokens: $inputTokens');
      debugPrint('💰 [GEMINI COST] Output Tokens: $outputTokens');
      debugPrint(
        '💰 [GEMINI COST] Total Tokens: ${inputTokens + outputTokens}',
      );
      debugPrint(
        '💰 [GEMINI COST] Input Cost: \$${inputCost.toStringAsFixed(6)}',
      );
      debugPrint(
        '💰 [GEMINI COST] Output Cost: \$${outputCost.toStringAsFixed(6)}',
      );
      debugPrint('💰 [GEMINI COST] TOTAL COST: \$${cost.toStringAsFixed(6)}');
      debugPrint(
        '💰 [GEMINI COST] File Size: ${(base64Data.length * 3 / 4 / 1024).toStringAsFixed(2)} KB',
      );
      debugPrint('💰 [GEMINI COST] Prompt Length: ${prompt.length} chars');
      debugPrint('💰 [GEMINI COST] Response Length: ${response.length} chars');
      debugPrint('💰 [GEMINI COST] ===== END COST BREAKDOWN =====');
    } catch (e) {
      debugPrint('❌ [GEMINI COST] Error calculating cost: $e');
    }
  }

  /// Log combined cost for a PDA prompt that uses both APIs
  static void logCombinedCost({
    required double vertexAiCost,
    required double geminiCost,
    required String promptDescription,
  }) {
    final totalCost = vertexAiCost + geminiCost;

    debugPrint('💰 [COMBINED COST] ===== TOTAL PROMPT COST =====');
    debugPrint('💰 [COMBINED COST] Prompt: $promptDescription');
    debugPrint(
      '💰 [COMBINED COST] Vertex AI Cost: \$${vertexAiCost.toStringAsFixed(6)}',
    );
    debugPrint(
      '💰 [COMBINED COST] Gemini Cost: \$${geminiCost.toStringAsFixed(6)}',
    );
    debugPrint(
      '💰 [COMBINED COST] TOTAL COST: \$${totalCost.toStringAsFixed(6)}',
    );
    debugPrint('💰 [COMBINED COST] ===== END TOTAL COST =====');
  }
}
