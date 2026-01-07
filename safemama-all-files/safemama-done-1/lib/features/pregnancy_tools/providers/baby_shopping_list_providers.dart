import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/baby_shopping_list_service.dart';

class BabyShoppingListState {
  final Map<String, List<Map<String, dynamic>>> shoppingData;
  final List<Map<String, dynamic>> wishlist;
  final Map<String, double> categoryBudgets;
  final bool isLoading;
  final String? error;
  final double totalEstimatedCost;
  final int totalItems;
  final int purchasedItems;

  const BabyShoppingListState({
    this.shoppingData = const {},
    this.wishlist = const [],
    this.categoryBudgets = const {},
    this.isLoading = false,
    this.error,
    this.totalEstimatedCost = 0.0,
    this.totalItems = 0,
    this.purchasedItems = 0,
  });

  BabyShoppingListState copyWith({
    Map<String, List<Map<String, dynamic>>>? shoppingData,
    List<Map<String, dynamic>>? wishlist,
    Map<String, double>? categoryBudgets,
    bool? isLoading,
    String? error,
    double? totalEstimatedCost,
    int? totalItems,
    int? purchasedItems,
  }) {
    return BabyShoppingListState(
      shoppingData: shoppingData ?? this.shoppingData,
      wishlist: wishlist ?? this.wishlist,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalEstimatedCost: totalEstimatedCost ?? this.totalEstimatedCost,
      totalItems: totalItems ?? this.totalItems,
      purchasedItems: purchasedItems ?? this.purchasedItems,
    );
  }
}

class BabyShoppingListNotifier extends StateNotifier<BabyShoppingListState> {
  final BabyShoppingListService _service;

  BabyShoppingListNotifier(this._service) : super(const BabyShoppingListState()) {
    _loadShoppingData();
  }

  Future<void> _loadShoppingData() async {
    state = state.copyWith(isLoading: true);

    try {
      final shoppingData = await _service.getShoppingData();
      final wishlist = await _service.getWishlist();
      final categoryBudgets = await _service.getCategoryBudgets();
      
      _updateStats(shoppingData);
      
      state = state.copyWith(
        shoppingData: shoppingData,
        wishlist: wishlist,
        categoryBudgets: categoryBudgets,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void toggleItemPurchased(String category, String itemId) {
    final updatedData = Map<String, List<Map<String, dynamic>>>.from(state.shoppingData);
    
    if (updatedData[category] != null) {
      final categoryItems = List<Map<String, dynamic>>.from(updatedData[category]!);
      
      for (int i = 0; i < categoryItems.length; i++) {
        if (categoryItems[i]['id'] == itemId) {
          categoryItems[i] = Map<String, dynamic>.from(categoryItems[i]);
          categoryItems[i]['checked'] = !(categoryItems[i]['checked'] as bool);
          
          if (categoryItems[i]['checked']) {
            categoryItems[i]['purchasedDate'] = DateTime.now().toIso8601String();
          } else {
            categoryItems[i].remove('purchasedDate');
          }
          break;
        }
      }
      
      updatedData[category] = categoryItems;
    }

    _updateStats(updatedData);
    state = state.copyWith(shoppingData: updatedData);
    
    _service.saveShoppingData(updatedData);
  }

  void addCustomItem({
    required String category,
    required String itemName,
    required String priceRange,
    required String priority,
    String? note,
  }) {
    final updatedData = Map<String, List<Map<String, dynamic>>>.from(state.shoppingData);
    
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'item': itemName,
      'price': priceRange,
      'checked': false,
      'priority': priority,
      'note': note ?? '',
      'isCustom': true,
    };

    if (updatedData[category] != null) {
      updatedData[category] = [...updatedData[category]!, newItem];
    } else {
      updatedData[category] = [newItem];
    }

    _updateStats(updatedData);
    state = state.copyWith(shoppingData: updatedData);
    
    _service.saveShoppingData(updatedData);
  }

  void addToWishlist(String category, String itemId) {
    final item = _findItem(category, itemId);
    if (item == null) return;

    final wishlistItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'originalId': itemId,
      'category': category,
      'item': item['item'],
      'price': item['price'],
      'priority': item['priority'],
      'addedDate': DateTime.now().toIso8601String(),
    };

    final updatedWishlist = [...state.wishlist, wishlistItem];
    
    state = state.copyWith(wishlist: updatedWishlist);
    _service.saveWishlist(updatedWishlist);
  }

  void removeFromWishlist(String wishlistItemId) {
    final updatedWishlist = state.wishlist
        .where((item) => item['id'] != wishlistItemId)
        .toList();
    
    state = state.copyWith(wishlist: updatedWishlist);
    _service.saveWishlist(updatedWishlist);
  }

  void updateItemNote(String category, String itemId, String note) {
    final updatedData = Map<String, List<Map<String, dynamic>>>.from(state.shoppingData);
    
    if (updatedData[category] != null) {
      final categoryItems = List<Map<String, dynamic>>.from(updatedData[category]!);
      
      for (int i = 0; i < categoryItems.length; i++) {
        if (categoryItems[i]['id'] == itemId) {
          categoryItems[i] = Map<String, dynamic>.from(categoryItems[i]);
          categoryItems[i]['note'] = note;
          break;
        }
      }
      
      updatedData[category] = categoryItems;
    }

    state = state.copyWith(shoppingData: updatedData);
    _service.saveShoppingData(updatedData);
  }

  void updateCategoryBudget(String category, double budget) {
    final updatedBudgets = Map<String, double>.from(state.categoryBudgets);
    updatedBudgets[category] = budget;
    
    state = state.copyWith(categoryBudgets: updatedBudgets);
    _service.saveCategoryBudgets(updatedBudgets);
  }

  void _updateStats(Map<String, List<Map<String, dynamic>>> shoppingData) {
    int totalItems = 0;
    int purchasedItems = 0;
    double totalCost = 0.0;

    for (final categoryItems in shoppingData.values) {
      totalItems += categoryItems.length;
      purchasedItems += categoryItems.where((item) => item['checked'] == true).length;
      
      for (final item in categoryItems) {
        final priceRange = _extractPriceRange(item['price'] as String);
        totalCost += priceRange['max']!.toDouble();
      }
    }

    state = state.copyWith(
      totalItems: totalItems,
      purchasedItems: purchasedItems,
      totalEstimatedCost: totalCost,
    );
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

  Map<String, dynamic>? _findItem(String category, String itemId) {
    final categoryItems = state.shoppingData[category];
    if (categoryItems == null) return null;
    
    try {
      return categoryItems.firstWhere((item) => item['id'] == itemId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> getShoppingStats() {
    return {
      'totalItems': state.totalItems,
      'purchasedItems': state.purchasedItems,
      'totalEstimatedCost': state.totalEstimatedCost,
      'completionPercentage': state.totalItems > 0 ? (state.purchasedItems / state.totalItems) : 0.0,
      'wishlistCount': state.wishlist.length,
    };
  }

  String getCategoryTotal(String category) {
    final categoryItems = state.shoppingData[category] ?? [];
    double minTotal = 0;
    double maxTotal = 0;
    
    for (final item in categoryItems) {
      final priceRange = _extractPriceRange(item['price'] as String);
      minTotal += priceRange['min']!.toDouble();
      maxTotal += priceRange['max']!.toDouble();
    }
    
    return '₹${minTotal.toInt()} - ₹${maxTotal.toInt()}';
  }
}

// Providers
final babyShoppingListServiceProvider = Provider<BabyShoppingListService>((ref) {
  return BabyShoppingListService();
});

final babyShoppingListProvider = StateNotifierProvider<BabyShoppingListNotifier, BabyShoppingListState>((ref) {
  final service = ref.watch(babyShoppingListServiceProvider);
  return BabyShoppingListNotifier(service);
});
