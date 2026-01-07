// lib/core/models/scan_data.dart

import 'dart:convert'; // Added for potential json.decode
import 'package:flutter/foundation.dart'; // For UniqueKey in fromPremiumSearchResult and ValueGetter

// Helper enum for RiskLevel
enum RiskLevel { safe, caution, avoid, unknown }

// Helper function to convert RiskLevel enum to a standardized string
String riskLevelToString(RiskLevel riskLevel) {
  switch (riskLevel) {
    case RiskLevel.safe: return "Safe";
    case RiskLevel.caution: return "Caution";
    case RiskLevel.avoid: return "NotSafe"; // Or "Avoid" - match your backend/AI output
    case RiskLevel.unknown:
    default: return "Unknown";
  }
}

// Helper function to parse a string into a RiskLevel enum
RiskLevel riskLevelFromString(String? riskString) {
  final String? processedRiskString = riskString?.trim().toLowerCase();
  print("[riskLevelFromString] Input: '$riskString', Processed: '$processedRiskString'"); // ACTION 1 CHANGE
  switch (processedRiskString) {
    case 'safe': return RiskLevel.safe;
    case 'caution':
    case 'use_with_caution':
      print("[riskLevelFromString] Matched 'use_with_caution' or 'caution'"); // ACTION 1 CHANGE
      return RiskLevel.caution;
    case 'notsafe':
    case 'not safe':
    case 'avoid': return RiskLevel.avoid;
    default:
      print("[riskLevelFromString] No match, returning Unknown."); // ACTION 1 CHANGE
      return RiskLevel.unknown;
  }
}

// Private helper function to safely parse a value from JSON into a String.
// If the value is a List, it's joined into a comma-separated string.
// If it's another non-null type, it's converted using toString().
String? _parseJsonValueToString(dynamic value, String keyForLog) {
  if (value == null) {
    print("[ScanData._parseJsonValueToString] Info: Field '$keyForLog' in analysis_result_json was null. Returning null.");
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is List) {
    if (value.isEmpty) {
      print("[ScanData._parseJsonValueToString] Info: Field '$keyForLog' in analysis_result_json was an empty List. Interpreting as null.");
      return null;
    }
    String joinedString = value.map((e) => e.toString()).join(', ');
    print("[ScanData._parseJsonValueToString] Info: Field '$keyForLog' in analysis_result_json was a List. Converted to string: '$joinedString'");
    return joinedString;
  }
  String stringValue = value.toString();
  print("[ScanData._parseJsonValueToString] Info: Field '$keyForLog' in analysis_result_json was of type ${value.runtimeType}. Converted to string: '$stringValue'");
  return stringValue;
}

// Helper function to parse a dynamic value from JSON into a List<String>?.
// Handles cases where the value is already a List or needs conversion.
List<String>? _parseJsonValueToList(dynamic value, String keyForLog) {
  if (value == null) {
    print("[ScanData._parseJsonValueToList] Info: Field '$keyForLog' in analysis_result_json was null. Returning null.");
    return null;
  }
  if (value is List) {
    if (value.isEmpty) {
      print("[ScanData._parseJsonValueToList] Info: Field '$keyForLog' in analysis_result_json was an empty List. Returning empty list.");
      return [];
    }
    try {
      return List<String>.from(value.map((item) => item.toString()));
    } catch (e) {
      print("[ScanData._parseJsonValueToList] Error converting list items to string for key '$keyForLog': $e. Returning null.");
      return null;
    }
  }
  print("[ScanData._parseJsonValueToList] Warning: Field '$keyForLog' in analysis_result_json was not a List. Received: ${value.runtimeType} ('$value'). Returning null.");
  return null;
}


class ScanData {
  final String? id;
  final String? userId;
  final DateTime createdAt;
  final String? scannedImagePath;
  final String productName;
  final String? brandName;
  final String? ingredientsText; // <<< ADDED FIELD
  final RiskLevel riskLevel;
  final String explanation;
  final String pregnancyTip;
  final List<String>? alternatives;
  final String? consumptionAdvice;
  final String? imageUrl;
  final List<String>? safetyTips;
  final List<String>? ingredients;
  final List<String>? nutrients;
  final List<String>? warnings;
  final bool isBookmarked;
  final String? rawResponse;
  final String? scannedImageType; // e.g., 'barcode', 'label', 'product', 'manual_search_result' // <<< ADDED
  final bool isFromManualSearch; // <<< ADDED

  ScanData({
    this.id,
    this.userId,
    required this.createdAt,
    this.scannedImagePath,
    required this.productName,
    this.brandName,
    this.ingredientsText, // <<< ADDED to constructor
    required this.riskLevel,
    required this.explanation,
    required this.pregnancyTip,
    this.alternatives,
    this.consumptionAdvice,
    this.imageUrl,
    this.safetyTips,
    this.ingredients,
    this.nutrients,
    this.warnings,
    this.isBookmarked = false,
    this.rawResponse,
    this.scannedImageType, // <<< ADDED
    this.isFromManualSearch = false, // <<< ADDED with a default
  });

  String get riskLevelString => riskLevelToString(this.riskLevel);

  factory ScanData.fromNavigationData(Map<String, dynamic> data) {
    List<String>? parseList(dynamic value) {
      if (value != null && value is List) {
        try {
          return List<String>.from(value.map((e) => e.toString()));
        } catch (e) {
          print("[ScanData.fromNavigationData.parseList] Error converting list items to string: $e. Returning null.");
          return null;
        }
      }
      return null;
    }

    return ScanData(
      id: data['id'] as String?,
      userId: data['userId'] as String?,
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      scannedImagePath: data['scannedImagePath'] as String?,
      productName: data['productName'] as String? ?? 'Unknown Product',
      brandName: data['brandName'] as String?,
      // ingredientsText is not handled here based on current instructions
      riskLevel: riskLevelFromString(data['riskLevel'] as String? ?? data['riskLevelString'] as String?),
      explanation: data['explanation'] as String? ?? 'No explanation available.',
      pregnancyTip: data['tip'] as String? ?? data['pregnancyTip'] as String? ?? 'No tip available.',
      alternatives: parseList(data['alternatives']),
      consumptionAdvice: data['consumptionAdvice'] as String?,
      imageUrl: data['imageUrl'] as String?,
      safetyTips: parseList(data['safetyTips']),
      ingredients: parseList(data['ingredients']),
      nutrients: parseList(data['nutrients']),
      warnings: parseList(data['warnings']),
      isBookmarked: data['isBookmarked'] as bool? ?? data['isExplicitlySaved'] as bool? ?? false,
      rawResponse: data['rawResponse'] as String?,
      scannedImageType: data['scannedImageType'] as String?, // <<< ADDED
      isFromManualSearch: data['isFromManualSearch'] as bool? ?? false, // <<< ADDED
    );
  }

  factory ScanData.fromPremiumSearchResult(Map<String, dynamic> premiumResultData, String currentUserId /*, int userTrimester */) {
    String? getString(dynamic value) => value is String ? value : null;
    String getRequiredString(dynamic value, String defaultValue) => value is String ? value : defaultValue;

    return ScanData(
      id: premiumResultData['id']?.toString() ?? UniqueKey().toString(),
      userId: currentUserId,
      createdAt: DateTime.now(),
      scannedImagePath: null,
      productName: getRequiredString(premiumResultData['product_name'], 'Unknown Product'),
      brandName: getString(premiumResultData['brand_name']),
      ingredientsText: getString(premiumResultData['description']) ?? getString(premiumResultData['ingredients_text']), // <<< ADDED mapping
      riskLevel: riskLevelFromString(getString(premiumResultData['safety_status_trimester1'])),
      explanation: getRequiredString(premiumResultData['safety_summary_trimester1'], 'No explanation available.'),
      pregnancyTip: getRequiredString(premiumResultData['generic_pregnancy_tip'], 'No tip available.'),
      alternatives: null,
      consumptionAdvice: getString(premiumResultData['consumption_advice']),
      imageUrl: getString(premiumResultData['image_url']),
      safetyTips: null,
      ingredients: null,
      nutrients: null,
      warnings: null,
      isBookmarked: false,
      rawResponse: premiumResultData.containsKey('detailed_analysis_json') && premiumResultData['detailed_analysis_json'] != null
          ? json.encode(premiumResultData['detailed_analysis_json']) // Ensure rawResponse gets the detailed_analysis_json
          : null,
      scannedImageType: 'manual_search_result', // <<< SET THIS
      isFromManualSearch: true,              // <<< SET THIS
    );
  }


  Map<String, dynamic> toAnalysisResultMap() {
    return {
      'productName': productName,
      'riskLevel': riskLevelString,
      'explanation': explanation,
      'tip': pregnancyTip,
      'alternatives': alternatives,
      'consumptionAdvice': consumptionAdvice,
      'safetyTips': safetyTips,
      'ingredients': ingredients,
      'nutrients': nutrients,
      'warnings': warnings,
      'rawResponse': rawResponse,
      // ingredientsText is not typically part of this JSON blob if it's a separate DB column
      // scannedImageType and isFromManualSearch are not part of this specific map
    };
  }

  ScanData copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    String? scannedImagePath,
    String? productName,
    String? brandName,
    ValueGetter<String?>? ingredientsText, // <<< Use ValueGetter for nullable to allow setting to null
    RiskLevel? riskLevel,
    String? explanation,
    String? pregnancyTip,
    List<String>? alternatives,
    String? consumptionAdvice,
    String? imageUrl,
    List<String>? safetyTips,
    List<String>? ingredients,
    List<String>? nutrients,
    List<String>? warnings,
    bool? isBookmarked,
    String? rawResponse,
    String? scannedImageType,    // <<< ADDED
    bool? isFromManualSearch,  // <<< ADDED
  }) {
    return ScanData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      scannedImagePath: scannedImagePath ?? this.scannedImagePath,
      productName: productName ?? this.productName,
      brandName: brandName ?? this.brandName,
      ingredientsText: ingredientsText != null ? ingredientsText() : this.ingredientsText, // <<< ADDED
      riskLevel: riskLevel ?? this.riskLevel,
      explanation: explanation ?? this.explanation,
      pregnancyTip: pregnancyTip ?? this.pregnancyTip,
      alternatives: alternatives ?? this.alternatives,
      consumptionAdvice: consumptionAdvice ?? this.consumptionAdvice,
      imageUrl: imageUrl ?? this.imageUrl,
      safetyTips: safetyTips ?? this.safetyTips,
      ingredients: ingredients ?? this.ingredients,
      nutrients: nutrients ?? this.nutrients,
      warnings: warnings ?? this.warnings,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      rawResponse: rawResponse ?? this.rawResponse,
      scannedImageType: scannedImageType ?? this.scannedImageType, // <<< ADDED
      isFromManualSearch: isFromManualSearch ?? this.isFromManualSearch, // <<< ADDED
    );
  }

  // Assuming fromDbMap is the factory for items from scan_history
  // In fromMap (for items from scan_history):
  factory ScanData.fromDbMap(Map<String, dynamic> map) { // Renamed from fromMap to match your existing code
    print("[ScanData.fromDbMap] Parsing DB map. Keys: ${map.keys.toList()}");

    DateTime parseTimestamp(String? timestamp) {
      if (timestamp == null) {
        print("[ScanData.fromDbMap.parseTimestamp] Timestamp is null. Using current time.");
        return DateTime.now();
      }
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print("[ScanData.fromDbMap.parseTimestamp] Error parsing timestamp '$timestamp': $e. Using current time as fallback.");
        return DateTime.now();
      }
    }

    String? tempId; try { tempId = map['id'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting id: $e. Value: ${map['id']}, Type: ${map['id'].runtimeType}. Defaulting to null."); tempId = null; }
    String? tempUserId; try { tempUserId = map['user_id'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting user_id: $e. Value: ${map['user_id']}, Type: ${map['user_id'].runtimeType}. Defaulting to null."); tempUserId = null; }
    String? tempScannedAtStr; try { tempScannedAtStr = map['scanned_at'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting scanned_at: $e. Value: ${map['scanned_at']}, Type: ${map['scanned_at'].runtimeType}. Defaulting to null."); tempScannedAtStr = null; }
    String? tempProductNameDb; try { tempProductNameDb = map['product_name'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting product_name: $e. Value: ${map['product_name']}, Type: ${map['product_name'].runtimeType}. Defaulting to null."); tempProductNameDb = null; }
    String? tempBrandNameDb; try { tempBrandNameDb = map['brand_name'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting brand_name: $e. Value: ${map['brand_name']}, Type: ${map['brand_name'].runtimeType}. Defaulting to null."); tempBrandNameDb = null; }
    String? tempIngredientsTextDb; try { tempIngredientsTextDb = map['ingredients_text'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting ingredients_text: $e. Value: ${map['ingredients_text']}, Type: ${map['ingredients_text']?.runtimeType}. Defaulting to null."); tempIngredientsTextDb = null; } // <<< ADDED parsing for ingredients_text
    String? tempRiskLevelDb; try { tempRiskLevelDb = map['risk_level'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting risk_level: $e. Value: ${map['risk_level']}, Type: ${map['risk_level'].runtimeType}. Defaulting to null."); tempRiskLevelDb = null; }
    String? tempImageUrl; try { tempImageUrl = map['product_image_url'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting product_image_url: $e. Value: ${map['product_image_url']}, Type: ${map['product_image_url'].runtimeType}. Defaulting to null."); tempImageUrl = null; }
    bool? tempIsBookmarked; try { tempIsBookmarked = map['is_bookmarked'] as bool?; } catch (e) { print("[ScanData.fromDbMap] Error casting is_bookmarked: $e. Value: ${map['is_bookmarked']}, Type: ${map['is_bookmarked'].runtimeType}. Defaulting to null."); tempIsBookmarked = null; }
    String? tempScannedImageType; try { tempScannedImageType = map['scanned_image_type'] as String?; } catch (e) { print("[ScanData.fromDbMap] Error casting scanned_image_type: $e. Value: ${map['scanned_image_type']}, Type: ${map['scanned_image_type']?.runtimeType}. Defaulting to null."); tempScannedImageType = null; } // <<< ADDED

    Map<String, dynamic> analysisJson = {};
    final dynamic rawValue = map['analysis_result_json'];

    if (rawValue != null) {
        if (rawValue is Map) {
            try {
                analysisJson = Map<String, dynamic>.from(rawValue);
                 print("[ScanData.fromDbMap] 'analysis_result_json' was a Map. Used directly.");
            } catch (e) {
                print("[ScanData.fromDbMap] Error casting 'analysis_result_json' (which was a Map: ${rawValue.runtimeType}) to Map<String, dynamic>: $e. Using default empty map.");
            }
        } else if (rawValue is String) {
            if (rawValue.trim().isEmpty) {
                print("[ScanData.fromDbMap] 'analysis_result_json' was an empty String. Using default empty map.");
            } else {
                try {
                  final decoded = json.decode(rawValue);
                  if (decoded is Map) {
                    analysisJson = Map<String, dynamic>.from(decoded);
                    print("[ScanData.fromDbMap] Successfully decoded 'analysis_result_json' string to Map.");
                  } else {
                    print("[ScanData.fromDbMap] Warning: 'analysis_result_json' was a String, but did not decode to a Map. Decoded type: ${decoded.runtimeType}. Using default empty map.");
                  }
                } catch (e) {
                  print("[ScanData.fromDbMap] Error decoding 'analysis_result_json' string to Map: $e. Raw string: '$rawValue'. Using default empty map.");
                }
            }
        } else {
           print("[ScanData.fromDbMap] Warning: 'analysis_result_json' was not a Map or String. Type: ${rawValue.runtimeType}. Value: '$rawValue'. Using default empty map.");
        }
    } else {
        print("[ScanData.fromDbMap] 'analysis_result_json' was null in the DB map. Using default empty map for analysisJson.");
    }

    String dbProductName = tempProductNameDb ?? _parseJsonValueToString(analysisJson['productName'], 'productName (from JSON)') ?? 'Unknown Product';
    String? dbBrandName = tempBrandNameDb ?? _parseJsonValueToString(analysisJson['brandName'], 'brandName (from JSON)');
    // ingredientsText is primarily expected from its own column (tempIngredientsTextDb)
    // or from premium search results, not typically from analysisJson unless specifically designed that way.

    String? safetyLevelFromJson = _parseJsonValueToString(analysisJson['safetyLevel'], 'safetyLevel (from JSON)');
    String? riskLevelFromJson = _parseJsonValueToString(analysisJson['riskLevel'], 'riskLevel (from JSON)');

    String? finalRiskStringForEnum = tempRiskLevelDb ?? safetyLevelFromJson ?? riskLevelFromJson;

    RiskLevel dbRiskLevel = riskLevelFromString(finalRiskStringForEnum);

    List<String>? dbSafetyTips = _parseJsonValueToList(analysisJson['safetyTips'], 'safetyTips (from JSON)');
    List<String>? dbAlternatives = _parseJsonValueToList(analysisJson['alternatives'], 'alternatives (from JSON)');
    List<String>? dbIngredients = _parseJsonValueToList(analysisJson['ingredients'], 'ingredients (from JSON)');
    List<String>? dbNutrients = _parseJsonValueToList(analysisJson['nutrients'], 'nutrients (from JSON)');
    List<String>? dbWarnings = _parseJsonValueToList(analysisJson['warnings'], 'warnings (from JSON)');

    String parsedTip = _parseJsonValueToString(analysisJson['tip'], 'tip (from JSON)') ??
                       _parseJsonValueToString(analysisJson['pregnancyTip'], 'pregnancyTip (from JSON)') ??
                       'No tip provided.';

    String parsedExplanation = _parseJsonValueToString(analysisJson['summary'], 'summary (from JSON)') ??
                               _parseJsonValueToString(analysisJson['explanation'], 'explanation (from JSON)') ??
                               'No explanation provided.';

    String? parsedRawResponse = _parseJsonValueToString(analysisJson['rawResponse'], 'rawResponse (from JSON)');

    return ScanData(
      id: tempId,
      userId: tempUserId,
      createdAt: parseTimestamp(tempScannedAtStr),
      productName: dbProductName,
      brandName: dbBrandName,
      ingredientsText: tempIngredientsTextDb, // <<< ADDED ingredientsText from DB map
      riskLevel: dbRiskLevel,
      explanation: parsedExplanation,
      pregnancyTip: parsedTip,
      alternatives: dbAlternatives,
      ingredients: dbIngredients,
      nutrients: dbNutrients,
      warnings: dbWarnings,
      safetyTips: dbSafetyTips,
      consumptionAdvice: _parseJsonValueToString(analysisJson['consumptionAdvice'], 'consumptionAdvice (from JSON)'),
      imageUrl: tempImageUrl,
      isBookmarked: tempIsBookmarked ?? false,
      rawResponse: rawValue is String ? rawValue : (rawValue != null ? json.encode(rawValue) : null), // Ensure rawResponse gets the original JSON string or map
      scannedImagePath: null, // This field is usually for image path of actual scan, not from DB like this.
      scannedImageType: tempScannedImageType, // <<< SET THIS (or map['scanned_image_type'] as String?)
      isFromManualSearch: false, // <<< Default to false for actual scans
    );
  }

  Map<String, dynamic> toJsonForOldDb(String currentUserId) {
    return {
      'user_id': currentUserId,
      'product_name': productName,
      'brand_name': brandName,
      'ingredients_text': ingredientsText, // <<< ADDED to map for DB
      'risk_level': riskLevelString,
      'analysis_result_json': toAnalysisResultMap(),
      'scanned_at': createdAt.toIso8601String(),
      'product_image_url': imageUrl,
      'is_bookmarked': isBookmarked,
      'scanned_image_type': scannedImageType, // <<< ADDED
      // isFromManualSearch is a runtime flag, not typically stored directly in scan_history
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'scannedImagePath': scannedImagePath,
      'productName': productName,
      'brandName': brandName,
      'ingredientsText': ingredientsText, // <<< ADDED
      'riskLevel': riskLevelToString(riskLevel),
      'explanation': explanation,
      'pregnancyTip': pregnancyTip,
      'alternatives': alternatives,
      'consumptionAdvice': consumptionAdvice,
      'imageUrl': imageUrl,
      'safetyTips': safetyTips,
      'ingredients': ingredients, // This is the List<String> version
      'nutrients': nutrients,
      'warnings': warnings,
      'isBookmarked': isBookmarked,
      'rawResponse': rawResponse,
      'scannedImageType': scannedImageType, // <<< ADDED
      'isFromManualSearch': isFromManualSearch, // <<< ADDED
    };
  }
}