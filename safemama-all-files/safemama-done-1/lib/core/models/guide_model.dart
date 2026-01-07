// lib/core/models/guide_model.dart
import 'package:flutter/foundation.dart';

class Guide {
  final dynamic id;
  final DateTime createdAt;
  final String title;
  final String contentMarkdown;
  final String? category;
  final List<int>? targetTrimesters;
  final String languageCode;
  final bool isPremiumOnly;
  final String? imageUrl;
  final String? shortSummary;

  Guide({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.contentMarkdown,
    this.category,
    this.targetTrimesters,
    required this.languageCode,
    required this.isPremiumOnly,
    this.imageUrl,
    this.shortSummary,
  });

  // ========== CORRECTED fromMap FACTORY ==========
  factory Guide.fromMap(Map<String, dynamic> map) {
    // Helper function to safely parse a list of integers from dynamic data
    List<int>? parseTrimesters(dynamic trimesters) {
      if (trimesters == null) return null;
      if (trimesters is List) {
        return trimesters.whereType<int>().toList();
      }
      return null;
    }

    try {
      return Guide(
        // --- Required Fields (will crash if null, which is good for debugging) ---
        id: map['id'],
        createdAt: DateTime.parse(map['created_at'] as String),
        title: map['title'] as String,
        contentMarkdown: map['content_markdown'] as String,
        
        // Your server guarantees 'language_code', so we cast it directly.
        languageCode: map['language_code'] as String,
        
        // Your server guarantees 'is_premium_only', so we cast it directly.
        isPremiumOnly: map['is_premium_only'] as bool,

        // --- Nullable Fields (safely handles null values) ---
        // Your server sends a non-null string, but we handle null for other guides.
        category: map['category'] as String?,
        
        // Your server sends a non-null string, but we handle null for other guides.
        shortSummary: map['short_summary'] as String?,

        // These are correctly handled as they can be null from the server.
        imageUrl: map['image_url'] as String?,
        targetTrimesters: parseTrimesters(map['target_trimesters']),
      );
    } catch (e, stackTrace) {
      // This will give you a very clear error in the debug console if parsing fails.
      debugPrint('Error parsing Guide from map: $e');
      debugPrint('Problematic Map Data: $map');
      debugPrint('Stack Trace: $stackTrace');
      // Re-throw the error to let the calling code know that parsing failed.
      rethrow;
    }
  }
}