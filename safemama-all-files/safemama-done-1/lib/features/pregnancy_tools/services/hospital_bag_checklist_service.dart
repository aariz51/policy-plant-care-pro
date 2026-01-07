import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class HospitalBagChecklistService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  // Default checklist data
  final Map<String, List<Map<String, dynamic>>> _defaultChecklistData = {
    'essentials': [
      {'id': '1', 'item': 'Insurance cards & ID', 'category': 'Documents', 'checked': false, 'priority': 'high'},
      {'id': '2', 'item': 'Birth plan copies', 'category': 'Documents', 'checked': false, 'priority': 'medium'},
      {'id': '3', 'item': 'Hospital registration papers', 'category': 'Documents', 'checked': false, 'priority': 'high'},
      {'id': '4', 'item': 'Phone & charger', 'category': 'Electronics', 'checked': false, 'priority': 'high'},
      {'id': '5', 'item': 'Camera', 'category': 'Electronics', 'checked': false, 'priority': 'medium'},
      {'id': '6', 'item': 'Comfortable going-home outfit', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
    ],
    'mom': [
      {'id': '7', 'item': 'Comfortable nightgowns', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'id': '8', 'item': 'Nursing bras (2-3)', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'id': '9', 'item': 'Comfortable underwear', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'id': '10', 'item': 'Slippers with grip', 'category': 'Footwear', 'checked': false, 'priority': 'high'},
      {'id': '11', 'item': 'Robe', 'category': 'Clothing', 'checked': false, 'priority': 'medium'},
      {'id': '12', 'item': 'Maternity pads', 'category': 'Personal Care', 'checked': false, 'priority': 'high'},
      {'id': '13', 'item': 'Nursing pads', 'category': 'Personal Care', 'checked': false, 'priority': 'high'},
      {'id': '14', 'item': 'Toiletries', 'category': 'Personal Care', 'checked': false, 'priority': 'high'},
      {'id': '15', 'item': 'Hair ties', 'category': 'Personal Care', 'checked': false, 'priority': 'medium'},
      {'id': '16', 'item': 'Lip balm', 'category': 'Personal Care', 'checked': false, 'priority': 'low'},
      {'id': '17', 'item': 'Snacks', 'category': 'Food', 'checked': false, 'priority': 'medium'},
    ],
    'baby': [
      {'id': '18', 'item': 'Going-home outfit (2 sizes)', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'id': '19', 'item': 'Onesies (newborn & 0-3 months)', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'id': '20', 'item': 'Sleep gowns or sleepers', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'id': '21', 'item': 'Socks or booties', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'id': '22', 'item': 'Hat', 'category': 'Clothing', 'checked': false, 'priority': 'medium'},
      {'id': '23', 'item': 'Swaddle blankets', 'category': 'Bedding', 'checked': false, 'priority': 'high'},
      {'id': '24', 'item': 'Car seat (installed)', 'category': 'Safety', 'checked': false, 'priority': 'high'},
      {'id': '25', 'item': 'Burp cloths', 'category': 'Feeding', 'checked': false, 'priority': 'medium'},
      {'id': '26', 'item': 'Diapers (if preferred brand)', 'category': 'Care', 'checked': false, 'priority': 'low'},
    ],
    'partner': [
      {'id': '27', 'item': 'Change of clothes', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'id': '28', 'item': 'Toiletries', 'category': 'Personal Care', 'checked': false, 'priority': 'high'},
      {'id': '29', 'item': 'Snacks & drinks', 'category': 'Food', 'checked': false, 'priority': 'medium'},
      {'id': '30', 'item': 'Pillow from home', 'category': 'Comfort', 'checked': false, 'priority': 'medium'},
      {'id': '31', 'item': 'Entertainment (books, tablet)', 'category': 'Entertainment', 'checked': false, 'priority': 'low'},
      {'id': '32', 'item': 'Comfortable shoes', 'category': 'Footwear', 'checked': false, 'priority': 'medium'},
      {'id': '33', 'item': 'Cash for parking/vending', 'category': 'Practical', 'checked': false, 'priority': 'medium'},
    ],
  };

  Future<Map<String, List<Map<String, dynamic>>>> getChecklistData() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('hospital_bag_checklist')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null) {
          return Map<String, List<Map<String, dynamic>>>.from(response['checklist_data']);
        }
      }

      // Try to get from local storage
      final localData = await _getChecklistDataLocally();
      if (localData.isNotEmpty) {
        return localData;
      }

      // Return default data if nothing found
      return _defaultChecklistData;
    } catch (e) {
      return _defaultChecklistData;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getChecklistDataLocally() async {
    try {
      final checklistStr = await _storageService.getString('hospital_bag_checklist');
      if (checklistStr != null) {
        // Parse checklist data - use proper JSON in production
        return {}; // Placeholder
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> saveChecklistData(Map<String, List<Map<String, dynamic>>> checklistData) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('hospital_bag_checklist')
            .upsert({
              'user_id': user.id,
              'checklist_data': checklistData,
              'updated_at': DateTime.now().toIso8601String(),
            });
      }

      await _saveChecklistDataLocally(checklistData);
    } catch (e) {
      await _saveChecklistDataLocally(checklistData);
    }
  }

  Future<void> _saveChecklistDataLocally(Map<String, List<Map<String, dynamic>>> checklistData) async {
    try {
      await _storageService.setString('hospital_bag_checklist', 
          checklistData.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<Map<String, dynamic>> getChecklistStats() async {
    try {
      final checklistData = await getChecklistData();
      
      int totalItems = 0;
      int completedItems = 0;
      Map<String, int> priorityBreakdown = {'high': 0, 'medium': 0, 'low': 0};
      Map<String, int> categoryBreakdown = {};

      for (final categoryItems in checklistData.values) {
        totalItems += categoryItems.length;
        
        for (final item in categoryItems) {
          if (item['checked'] == true) {
            completedItems++;
          }
          
          final priority = item['priority'] as String;
          priorityBreakdown[priority] = (priorityBreakdown[priority] ?? 0) + 1;
          
          final category = item['category'] as String;
          categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
        }
      }

      return {
        'totalItems': totalItems,
        'completedItems': completedItems,
        'completionPercentage': totalItems > 0 ? (completedItems / totalItems) : 0.0,
        'priorityBreakdown': priorityBreakdown,
        'categoryBreakdown': categoryBreakdown,
        'isReady': totalItems > 0 ? (completedItems / totalItems) >= 0.8 : false,
      };
    } catch (e) {
      return {
        'totalItems': 0,
        'completedItems': 0,
        'completionPercentage': 0.0,
        'priorityBreakdown': {'high': 0, 'medium': 0, 'low': 0},
        'categoryBreakdown': {},
        'isReady': false,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getIncompleteHighPriorityItems() async {
    try {
      final checklistData = await getChecklistData();
      final highPriorityIncomplete = <Map<String, dynamic>>[];

      for (final categoryItems in checklistData.values) {
        for (final item in categoryItems) {
          if (item['priority'] == 'high' && item['checked'] == false) {
            highPriorityIncomplete.add(item);
          }
        }
      }

      return highPriorityIncomplete;
    } catch (e) {
      return [];
    }
  }

  Future<void> resetChecklist() async {
    try {
      final defaultData = Map<String, List<Map<String, dynamic>>>.from(_defaultChecklistData);
      await saveChecklistData(defaultData);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> exportChecklist() async {
    // Implementation for exporting checklist
    // This could generate a PDF or text file
    try {
      final checklistData = await getChecklistData();
      final stats = await getChecklistStats();
      
      // In production, you'd generate actual export file
      // For now, this is a placeholder
    } catch (e) {
      // Handle error silently
    }
  }
}
