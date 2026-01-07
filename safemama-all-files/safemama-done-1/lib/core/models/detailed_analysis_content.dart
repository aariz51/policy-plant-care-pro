// lib/core/models/detailed_analysis_content.dart
import 'package:safemama/l10n/app_localizations.dart';

// This is the simplified data model that the UI will use.
class DetailedAnalysisContent {
  final String productName;
  final String overallSafety;
  final String safetySummary;
  final List<String> ingredients;
  final List<String> nutrients;
  final List<String> warnings;
  final List<String> alternatives;
  final String? pregnancyTip;

  DetailedAnalysisContent({
    required this.productName,
    required this.overallSafety,
    required this.safetySummary,
    required this.ingredients,
    required this.nutrients,
    required this.warnings,
    required this.alternatives,
    this.pregnancyTip,
  });

  // This factory now correctly parses the JSON from the backend.
  factory DetailedAnalysisContent.fromJson(Map<String, dynamic> json, AppLocalizations S) {
    List<String> parseList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return DetailedAnalysisContent(
      productName: json['productName'] as String? ?? S.unknownProductName,
      overallSafety: json['safetyLevel'] as String? ?? json['overallSafety'] as String? ?? 'unknown',
      safetySummary: json['summary'] as String? ?? json['safetySummary'] as String? ?? 'No summary.',
      ingredients: parseList(json['ingredients']),
      nutrients: parseList(json['nutrients']),
      warnings: parseList(json['warnings'] ?? json['specificConcernsForPregnancy']),
      alternatives: parseList(json['alternatives']),
      pregnancyTip: json['pregnancyTip'] as String?,
    );
  }
}