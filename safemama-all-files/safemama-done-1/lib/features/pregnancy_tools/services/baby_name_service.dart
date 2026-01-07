import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod provider for injection/easy usage in UI
final babyNameServiceProvider = Provider<BabyNameService>((ref) {
  final api = ref.read(apiServiceProvider);
  return BabyNameService(api);
});

class BabyNameService {
  final ApiService _api;

  BabyNameService(this._api);

  Future<List<Map<String, dynamic>>> generateBabyNames({
    required String gender,
    required String origin,
    required String meaning,
    String? preferences,
    int count = 10,
  }) async {
    final response = await _api.post(
      '/pregnancy-tools/baby-name-generator',
      {
        'gender': gender,
        'origin': origin,
        'meaning': meaning,
        'preferences': preferences ?? 'Islamic guidelines compliant',
        'count': count,
      },
    );
    if (response['suggestions'] != null) {
      return List<Map<String, dynamic>>.from(response['suggestions']);
    } else if (response['error'] != null) {
      throw Exception(response['error']);
    }
    throw Exception('Invalid response from server');
  }
}
