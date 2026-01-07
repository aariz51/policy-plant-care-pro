import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class BabyShoppingListService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  // Default shopping data
  final Map<String, List<Map<String, dynamic>>> _defaultShoppingData = {
    'feeding': [
      {'id': '1', 'item': 'Bottles (4-6)', 'price': '₹800-1200', 'checked': false, 'priority': 'high', 'note': 'BPA-free preferred'},
      {'id': '2', 'item': 'Bottle brush', 'price': '₹200-400', 'checked': false, 'priority': 'high', 'note': ''},
      {'id': '3', 'item': 'Burp cloths (6-8)', 'price': '₹600-1000', 'checked': false, 'priority': 'high', 'note': ''},
      {'id': '4', 'item': 'Bibs (6-10)', 'price': '₹500-800', 'checked': false, 'priority': 'medium', 'note': 'Waterproof backing'},
      {'id': '5', 'item': 'Breast pump', 'price': '₹3000-8000', 'checked': false, 'priority': 'medium', 'note': 'Electric recommended'},
      {'id': '6', 'item': 'Nursing pillow', 'price': '₹1200-2500', 'checked': false, 'priority': 'medium', 'note': ''},
      {'id': '7', 'item': 'Sterilizer', 'price': '₹2000-5000', 'checked': false, 'priority': 'high', 'note': 'Steam or UV'},
      {'id': '8', 'item': 'Formula (if needed)', 'price': '₹800-1200', 'checked': false, 'priority': 'low', 'note': 'Consult doctor'},
    ],
    'clothing': [
      {'id': '9', 'item': 'Onesies (8-10)', 'price': '₹1200-2000', 'checked': false, 'priority': 'high', 'note': 'Mix of NB & 0-3M'},
      {'id': '10', 'item': 'Sleep gowns (6-8)', 'price': '₹1000-1600', 'checked': false, 'priority': 'high', 'note': 'Easy diaper access'},
      {'id': '11', 'item': 'Pants/Leggings (6-8)', 'price': '₹800-1400', 'checked': false, 'priority': 'medium', 'note': ''},
      {'id': '12', 'item': 'Socks (8-12 pairs)', 'price': '₹400-600', 'checked': false, 'priority': 'high', 'note': 'Stay-on design'},
      {'id': '13', 'item': 'Hats (3-4)', 'price': '₹300-600', 'checked': false, 'priority': 'medium', 'note': 'Soft cotton'},
      {'id': '14', 'item': 'Mittens (2-3 pairs)', 'price': '₹200-400', 'checked': false, 'priority': 'medium', 'note': 'Prevent scratching'},
      {'id': '15', 'item': 'Swaddle blankets (4-6)', 'price': '₹1200-2400', 'checked': false, 'priority': 'high', 'note': 'Muslin preferred'},
      {'id': '16', 'item': 'Going-home outfit', 'price': '₹800-1500', 'checked': false, 'priority': 'high', 'note': '2 sizes'},
    ],
    'bathing': [
      {'id': '17', 'item': 'Baby bathtub', 'price': '₹800-2000', 'checked': false, 'priority': 'high', 'note': 'Non-slip bottom'},
      {'id': '18', 'item': 'Bath towels (3-4)', 'price': '₹1200-2000', 'checked': false, 'priority': 'high', 'note': 'Hooded preferred'},
      {'id': '19', 'item': 'Washcloths (8-10)', 'price': '₹400-800', 'checked': false, 'priority': 'high', 'note': 'Soft cotton'},
      {'id': '20', 'item': 'Baby shampoo/body wash', 'price': '₹300-800', 'checked': false, 'priority': 'high', 'note': 'Tear-free formula'},
      {'id': '21', 'item': 'Baby lotion', 'price': '₹200-600', 'checked': false, 'priority': 'medium', 'note': 'Hypoallergenic'},
      {'id': '22', 'item': 'Bath thermometer', 'price': '₹200-500', 'checked': false, 'priority': 'medium', 'note': 'Digital preferred'},
      {'id': '23', 'item': 'Bath support/seat', 'price': '₹600-1500', 'checked': false, 'priority': 'low', 'note': 'For later'},
    ],
    'diapering': [
      {'id': '24', 'item': 'Diapers (NB & Size 1)', 'price': '₹1000-2000', 'checked': false, 'priority': 'high', 'note': 'Start with small packs'},
      {'id': '25', 'item': 'Baby wipes', 'price': '₹400-800', 'checked': false, 'priority': 'high', 'note': 'Sensitive skin'},
      {'id': '26', 'item': 'Diaper rash cream', 'price': '₹200-500', 'checked': false, 'priority': 'high', 'note': 'Zinc oxide based'},
      {'id': '27', 'item': 'Changing pad', 'price': '₹800-1500', 'checked': false, 'priority': 'high', 'note': 'Waterproof'},
      {'id': '28', 'item': 'Diaper pail', 'price': '₹1500-3000', 'checked': false, 'priority': 'medium', 'note': 'Odor control'},
      {'id': '29', 'item': 'Baby powder', 'price': '₹150-400', 'checked': false, 'priority': 'low', 'note': 'Talc-free'},
      {'id': '30', 'item': 'Cloth diapers (if using)', 'price': '₹2000-5000', 'checked': false, 'priority': 'low', 'note': 'Eco-friendly option'},
    ],
    'nursery': [
      {'id': '31', 'item': 'Crib/Cot', 'price': '₹5000-15000', 'checked': false, 'priority': 'high', 'note': 'Safety certified'},
      {'id': '32', 'item': 'Crib mattress', 'price': '₹2000-8000', 'checked': false, 'priority': 'high', 'note': 'Firm & breathable'},
      {'id': '33', 'item': 'Fitted crib sheets (3-4)', 'price': '₹800-1600', 'checked': false, 'priority': 'high', 'note': 'Organic cotton'},
      {'id': '34', 'item': 'Night light', 'price': '₹500-1500', 'checked': false, 'priority': 'medium', 'note': 'Dimmable'},
      {'id': '35', 'item': 'Blackout curtains', 'price': '₹1000-3000', 'checked': false, 'priority': 'medium', 'note': 'Better sleep'},
      {'id': '36', 'item': 'White noise machine', 'price': '₹1500-4000', 'checked': false, 'priority': 'medium', 'note': 'Sleep aid'},
      {'id': '37', 'item': 'Mobile', 'price': '₹1000-3000', 'checked': false, 'priority': 'low', 'note': 'Visual stimulation'},
      {'id': '38', 'item': 'Dresser/changing table', 'price': '₹8000-25000', 'checked': false, 'priority': 'medium', 'note': 'Safety straps'},
    ],
    'safety': [
      {'id': '39', 'item': 'Car seat', 'price': '₹8000-25000', 'checked': false, 'priority': 'high', 'note': 'Infant carrier'},
      {'id': '40', 'item': 'Stroller', 'price': '₹5000-20000', 'checked': false, 'priority': 'high', 'note': 'Travel system compatible'},
      {'id': '41', 'item': 'Baby gates', 'price': '₹2000-5000', 'checked': false, 'priority': 'low', 'note': 'For later mobility'},
      {'id': '42', 'item': 'Outlet covers', 'price': '₹200-500', 'checked': false, 'priority': 'low', 'note': 'Childproofing'},
      {'id': '43', 'item': 'Corner guards', 'price': '₹300-800', 'checked': false, 'priority': 'low', 'note': 'Furniture protection'},
      {'id': '44', 'item': 'Cabinet locks', 'price': '₹500-1200', 'checked': false, 'priority': 'low', 'note': 'Later safety'},
      {'id': '45', 'item': 'Baby monitor', 'price': '₹3000-12000', 'checked': false, 'priority': 'medium', 'note': 'Audio/video options'},
    ],
  };

  Future<Map<String, List<Map<String, dynamic>>>> getShoppingData() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('baby_shopping_list')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null) {
          return Map<String, List<Map<String, dynamic>>>.from(response['shopping_data']);
        }
      }

      final localData = await _getShoppingDataLocally();
      if (localData.isNotEmpty) {
        return localData;
      }

      return _defaultShoppingData;
    } catch (e) {
      return _defaultShoppingData;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getShoppingDataLocally() async {
    try {
      final shoppingStr = await _storageService.getString('baby_shopping_data');
      if (shoppingStr != null) {
        // Parse shopping data - use proper JSON in production
        return {}; // Placeholder
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> saveShoppingData(Map<String, List<Map<String, dynamic>>> shoppingData) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('baby_shopping_list')
            .upsert({
              'user_id': user.id,
              'shopping_data': shoppingData,
              'updated_at': DateTime.now().toIso8601String(),
            });
      }

      await _saveShoppingDataLocally(shoppingData);
    } catch (e) {
      await _saveShoppingDataLocally(shoppingData);
    }
  }

  Future<void> _saveShoppingDataLocally(Map<String, List<Map<String, dynamic>>> shoppingData) async {
    try {
      await _storageService.setString('baby_shopping_data', 
          shoppingData.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getWishlist() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('shopping_wishlist')
            .select()
            .eq('user_id', user.id)
            .order('added_date', ascending: false);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getWishlistLocally();
    } catch (e) {
      return await _getWishlistLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getWishlistLocally() async {
    try {
      final wishlistStr = await _storageService.getString('shopping_wishlist');
      if (wishlistStr != null) {
        // Parse wishlist - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWishlist(List<Map<String, dynamic>> wishlist) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        // Delete existing wishlist items
        await _supabase
            .from('shopping_wishlist')
            .delete()
            .eq('user_id', user.id);

        // Insert new wishlist items
        if (wishlist.isNotEmpty) {
          final wishlistData = wishlist.map((item) => {
            ...item,
            'user_id': user.id,
          }).toList();

          await _supabase
              .from('shopping_wishlist')
              .insert(wishlistData);
        }
      }

      await _saveWishlistLocally(wishlist);
    } catch (e) {
      await _saveWishlistLocally(wishlist);
    }
  }

  Future<void> _saveWishlistLocally(List<Map<String, dynamic>> wishlist) async {
    try {
      await _storageService.setString('shopping_wishlist', 
          wishlist.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<Map<String, double>> getCategoryBudgets() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('category_budgets')
            .select()
            .eq('user_id', user.id);

        if (response.isNotEmpty) {
          final budgets = <String, double>{};
          for (final budget in response) {
            budgets[budget['category']] = budget['budget_amount'].toDouble();
          }
          return budgets;
        }
      }

      return await _getCategoryBudgetsLocally();
    } catch (e) {
      return await _getCategoryBudgetsLocally();
    }
  }

  Future<Map<String, double>> _getCategoryBudgetsLocally() async {
    try {
      final budgetsStr = await _storageService.getString('category_budgets');
      if (budgetsStr != null) {
        // Parse budgets - use proper JSON in production
        return {}; // Placeholder
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> saveCategoryBudgets(Map<String, double> budgets) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        // Delete existing budgets
        await _supabase
            .from('category_budgets')
            .delete()
            .eq('user_id', user.id);

        // Insert new budgets
        if (budgets.isNotEmpty) {
          final budgetData = budgets.entries.map((entry) => {
            'user_id': user.id,
            'category': entry.key,
            'budget_amount': entry.value,
            'created_at': DateTime.now().toIso8601String(),
          }).toList();

          await _supabase
              .from('category_budgets')
              .insert(budgetData);
        }
      }

      await _saveCategoryBudgetsLocally(budgets);
    } catch (e) {
      await _saveCategoryBudgetsLocally(budgets);
    }
  }

  Future<void> _saveCategoryBudgetsLocally(Map<String, double> budgets) async {
    try {
      await _storageService.setString('category_budgets', 
          budgets.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<Map<String, dynamic>> getShoppingStats() async {
    try {
      final shoppingData = await getShoppingData();
      final wishlist = await getWishlist();
      
      int totalItems = 0;
      int purchasedItems = 0;
      double totalEstimatedCost = 0.0;
      Map<String, int> priorityBreakdown = {'high': 0, 'medium': 0, 'low': 0};
      Map<String, double> categoryTotals = {};

      for (final entry in shoppingData.entries) {
        final category = entry.key;
        final items = entry.value;
        
        totalItems += items.length;
        double categoryTotal = 0.0;

        for (final item in items) {
          if (item['checked'] == true) {
            purchasedItems++;
          }
          
          final priority = item['priority'] as String;
          priorityBreakdown[priority] = (priorityBreakdown[priority] ?? 0) + 1;
          
          // Extract price range and add to totals
          final priceRange = _extractPriceRange(item['price'] as String);
          final maxPrice = priceRange['max']?.toDouble() ?? 0.0;
          totalEstimatedCost += maxPrice;
          categoryTotal += maxPrice;
        }
        
        categoryTotals[category] = categoryTotal;
      }

      return {
        'totalItems': totalItems,
        'purchasedItems': purchasedItems,
        'totalEstimatedCost': totalEstimatedCost,
        'completionPercentage': totalItems > 0 ? (purchasedItems / totalItems) : 0.0,
        'priorityBreakdown': priorityBreakdown,
        'categoryTotals': categoryTotals,
        'wishlistCount': wishlist.length,
      };
    } catch (e) {
      return {
        'totalItems': 0,
        'purchasedItems': 0,
        'totalEstimatedCost': 0.0,
        'completionPercentage': 0.0,
        'priorityBreakdown': {'high': 0, 'medium': 0, 'low': 0},
        'categoryTotals': {},
        'wishlistCount': 0,
      };
    }
  }

  Map<String, int> _extractPriceRange(String priceStr) {
    final regex = RegExp(r'₹(\d+)-(\d+)');
    final match = regex.firstMatch(priceStr);
    
    if (match != null) {
      return {
        'min': int.parse(match.group(1)!),
        'max': int.parse(match.group(2)!),
      };
    }
    
    return {'min': 0, 'max': 0};
  }
}
