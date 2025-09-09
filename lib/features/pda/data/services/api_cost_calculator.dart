import 'package:flutter/foundation.dart';

class ApiCostCalculator {
  // Pricing per 1M tokens (as of 2024) - CORRECTED PRICES
  static const double _vertexClaudeSonnet4InputCost =
      3.0; // $3 per 1M input tokens (Claude 3.5 Sonnet)
  static const double _vertexClaudeSonnet4OutputCost =
      15.0; // $15 per 1M output tokens (Claude 3.5 Sonnet)
  static const double _gemini2FlashInputCost =
      0.10; // $0.10 per 1M input tokens (Gemini 2.0 Flash)
  static const double _gemini2FlashOutputCost =
      0.40; // $0.40 per 1M output tokens (Gemini 2.0 Flash)

  /// Calculate cost for Vertex AI Claude Sonnet 4
  static double calculateVertexClaudeCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    final inputCost = (inputTokens / 1000000) * _vertexClaudeSonnet4InputCost;
    final outputCost =
        (outputTokens / 1000000) * _vertexClaudeSonnet4OutputCost;
    final totalCost = inputCost + outputCost;

    debugPrint(
      '💰 [COST] Vertex Claude - Input: ${inputTokens} tokens (\$${inputCost.toStringAsFixed(6)}), Output: ${outputTokens} tokens (\$${outputCost.toStringAsFixed(6)}), Total: \$${totalCost.toStringAsFixed(6)}',
    );

    return totalCost;
  }

  /// Calculate cost for Gemini 2 Flash
  static double calculateGemini2FlashCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    final inputCost = (inputTokens / 1000000) * _gemini2FlashInputCost;
    final outputCost = (outputTokens / 1000000) * _gemini2FlashOutputCost;
    final totalCost = inputCost + outputCost;

    debugPrint(
      '💰 [COST] Gemini 2 Flash - Input: ${inputTokens} tokens (\$${inputCost.toStringAsFixed(6)}), Output: ${outputTokens} tokens (\$${outputCost.toStringAsFixed(6)}), Total: \$${totalCost.toStringAsFixed(6)}',
    );

    return totalCost;
  }

  /// Estimate tokens from text (rough approximation: 1 token ≈ 4 characters)
  static int estimateTokensFromText(String text) {
    return (text.length / 4).ceil();
  }

  /// Estimate tokens from images (rough approximation: 1 image ≈ 1000 tokens)
  static int estimateTokensFromImages(int imageCount) {
    return imageCount * 1000;
  }

  /// Calculate total cost for a PDA response
  static double calculatePdaResponseCost({
    required String userMessage,
    required String aiResponse,
    required int imageCount,
    required bool usedVertexClaude,
    required bool usedGemini,
  }) {
    double totalCost = 0.0;

    // Estimate tokens
    final userTokens = estimateTokensFromText(userMessage);
    final responseTokens = estimateTokensFromText(aiResponse);
    final imageTokens = estimateTokensFromImages(imageCount);
    final totalInputTokens = userTokens + imageTokens;

    // Calculate costs based on which services were used
    if (usedVertexClaude) {
      totalCost += calculateVertexClaudeCost(
        inputTokens: totalInputTokens,
        outputTokens: responseTokens,
      );
    }

    if (usedGemini) {
      totalCost += calculateGemini2FlashCost(
        inputTokens: totalInputTokens,
        outputTokens: responseTokens,
      );
    }

    debugPrint(
      '💰 [COST] Total PDA Response Cost: \$${totalCost.toStringAsFixed(6)}',
    );

    return totalCost;
  }

  /// Format cost for display
  static String formatCost(double cost) {
    if (cost < 0.001) {
      return '\$${(cost * 1000).toStringAsFixed(2)}m'; // Show in millicents
    } else if (cost < 0.01) {
      return '\$${(cost * 100).toStringAsFixed(2)}c'; // Show in cents
    } else {
      return '\$${cost.toStringAsFixed(4)}'; // Show in dollars
    }
  }
}
