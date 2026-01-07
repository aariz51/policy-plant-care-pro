// Create a utility class for safe string handling
// lib/utils/safe_string_utils.dart
class SafeStringUtils {
  static String safeString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }
  
  static String? safeNullableString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}

// Usage in your widgets:
Text(SafeStringUtils.safeString(userData?.name, 'Unknown')),
