// lib/core/services/revenuecat_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:safemama/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RevenueCat service for managing in-app subscriptions across iOS and Android
/// This service replaces the custom IAP services and provides a unified subscription management solution
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  static const String _TAG = '[RevenueCat]';
  
  // PRODUCTION API Keys (from RevenueCat Dashboard → Apps & providers)
  // These same keys work for both production AND sandbox testing!
  static const String _iosApiKey = 'appl_LNxJIBypCrfKUSoNRIyxFQIFZlL';
  static const String _androidApiKey = 'goog_PoETKwxxDqaEviGErXObyZEGunP';
  
  // SharedPreferences key to track if migration sync has been completed
  static const String _migrationSyncedKey = 'revenuecat_migration_synced';
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  String? _currentAppUserId;
  CustomerInfo? _cachedCustomerInfo;
  
  // Environment label for debugging
  // In debug mode, purchases go through sandbox/test accounts
  // In release mode, purchases are real
  String get environmentLabel => kDebugMode ? 'SANDBOX' : 'PRODUCTION';
  
  /// Initialize RevenueCat with the user's ID
  /// This should be called after user login/authentication
  /// 
  /// [appUserId] - The Supabase user ID to identify the user in RevenueCat
  Future<void> initRevenueCat(String appUserId) async {
    if (_isInitialized && _currentAppUserId == appUserId) {
      print('$_TAG Already initialized for user: $appUserId');
      return;
    }

    try {
      print('$_TAG [$environmentLabel] Initializing RevenueCat for user: $appUserId');
      
      // Configure RevenueCat SDK with platform-specific production keys
      // Sandbox vs Production is determined automatically by:
      // - iOS: Uses sandbox when running from Xcode or with sandbox Apple ID
      // - Android: Uses sandbox when app is installed via debug/test track or with license testers
      PurchasesConfiguration configuration;
      
      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_iosApiKey)..appUserID = appUserId;
        print('$_TAG [$environmentLabel] Using iOS API key');
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_androidApiKey)..appUserID = appUserId;
        print('$_TAG [$environmentLabel] Using Android API key');
        print('$_TAG [$environmentLabel] Sandbox mode: Use Play Console License Testers');
      } else {
        throw Exception('Unsupported platform for RevenueCat');
      }
      
      // Enable debug logs in debug mode
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      
      // Initialize the SDK
      await Purchases.configure(configuration);
      
      _isInitialized = true;
      _currentAppUserId = appUserId;
      
      print('$_TAG [$environmentLabel] Successfully initialized for user: $appUserId');
      
      // Set up customer info update listener
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        print('$_TAG [$environmentLabel] Customer info updated');
        _cachedCustomerInfo = customerInfo;
        _handleCustomerInfoUpdate(customerInfo);
      });
      
      // Fetch initial customer info
      _cachedCustomerInfo = await Purchases.getCustomerInfo();
      _logCustomerInfo(_cachedCustomerInfo);
      
    } on PlatformException catch (e) {
      print('$_TAG PlatformException during initialization: ${e.message}');
      rethrow;
    } catch (e) {
      print('$_TAG Error initializing RevenueCat: $e');
      rethrow;
    }
  }
  
  /// Get available subscription offerings from RevenueCat
  /// Returns the default offering with available packages (weekly, monthly, yearly)
  Future<Offering?> getOfferings() async {
    if (!_isInitialized) {
      print('$_TAG Cannot get offerings - RevenueCat not initialized');
      throw Exception('RevenueCat not initialized. Call initRevenueCat() first.');
    }
    
    try {
      print('$_TAG Fetching offerings...');
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current == null) {
        print('$_TAG No current offering available');
        return null;
      }
      
      final currentOffering = offerings.current!;
      print('$_TAG Found offering: ${currentOffering.identifier}');
      print('$_TAG Available packages: ${currentOffering.availablePackages.map((p) => p.identifier).toList()}');
      
      return currentOffering;
    } on PlatformException catch (e) {
      print('$_TAG PlatformException fetching offerings: ${e.message}');
      return null;
    } catch (e) {
      print('$_TAG Error fetching offerings: $e');
      return null;
    }
  }
  
  /// Purchase a subscription package
  /// This initiates the platform-specific purchase flow (App Store or Play Store)
  /// 
  /// [package] - The RevenueCat package to purchase
  /// [accessToken] - The user's Supabase access token for backend verification
  /// 
  /// Returns a map with 'success' (bool) and optional 'error' (String)
  Future<Map<String, dynamic>> purchasePackage(Package package, String accessToken) async {
    if (!_isInitialized) {
      return {
        'success': false,
        'error': 'RevenueCat not initialized'
      };
    }
    
    try {
      print('$_TAG Starting purchase for package: ${package.identifier}');
      print('$_TAG Product: ${package.storeProduct.identifier} - ${package.storeProduct.priceString}');
      
      // Initiate the purchase through RevenueCat
      final customerInfo = await Purchases.purchasePackage(package);
      
      print('$_TAG Purchase completed. Customer info updated.');
      _cachedCustomerInfo = customerInfo;
      
      // Check if the purchase was successful by verifying entitlements
      final hasActiveEntitlement = customerInfo.entitlements.active.isNotEmpty;
      
      if (hasActiveEntitlement) {
        print('$_TAG Purchase successful! Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
        
        // Sync with backend to update user's membership tier
        final syncResult = await _syncPurchaseWithBackend(
          customerInfo,
          accessToken,
        );
        
        if (syncResult['success'] == true) {
          return {'success': true};
        } else {
          print('$_TAG WARNING: Purchase successful but backend sync failed: ${syncResult['error']}');
          return {
            'success': true,
            'warning': 'Purchase successful but backend sync failed. Please contact support if premium features are not unlocked.'
          };
        }
      } else {
        print('$_TAG Purchase completed but no active entitlements found');
        return {
          'success': false,
          'error': 'Purchase completed but subscription not activated'
        };
      }
      
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      final errorMessage = e.message ?? 'Unknown error';
      
      print('$_TAG Purchase failed with error code: $errorCode, message: $errorMessage');
      
      // Handle specific error cases
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return {
          'success': false,
          'error': 'Purchase cancelled',
          'userCancelled': true
        };
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        return {
          'success': false,
          'error': 'Payment is pending. Please wait for confirmation.',
          'isPending': true
        };
      } else {
        return {
          'success': false,
          'error': errorMessage
        };
      }
    } catch (e) {
      print('$_TAG Unexpected error during purchase: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}'
      };
    }
  }
  
  /// Restore previous purchases
  /// This is useful when user reinstalls the app or switches devices
  /// 
  /// [accessToken] - The user's Supabase access token for backend verification
  /// 
  /// Returns a map with 'success' (bool) and optional 'error' (String)
  Future<Map<String, dynamic>> restorePurchases(String accessToken) async {
    if (!_isInitialized) {
      return {
        'success': false,
        'error': 'RevenueCat not initialized'
      };
    }
    
    try {
      print('$_TAG Restoring purchases...');
      
      final customerInfo = await Purchases.restorePurchases();
      _cachedCustomerInfo = customerInfo;
      
      print('$_TAG Restore completed. Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
      
      if (customerInfo.entitlements.active.isEmpty) {
        print('$_TAG No active subscriptions found to restore');
        return {
          'success': true,
          'message': 'No active subscriptions found'
        };
      }
      
      // Sync restored purchases with backend
      final syncResult = await _syncPurchaseWithBackend(customerInfo, accessToken);
      
      if (syncResult['success'] == true) {
        return {
          'success': true,
          'message': 'Purchases restored successfully'
        };
      } else {
        print('$_TAG WARNING: Restore successful but backend sync failed: ${syncResult['error']}');
        return {
          'success': true,
          'warning': 'Purchases restored but backend sync failed. Please contact support if premium features are not unlocked.'
        };
      }
      
    } on PlatformException catch (e) {
      print('$_TAG Error restoring purchases: ${e.message}');
      return {
        'success': false,
        'error': e.message ?? 'Failed to restore purchases'
      };
    } catch (e) {
      print('$_TAG Unexpected error restoring purchases: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}'
      };
    }
  }
  
  /// Sync existing App Store/Play Store subscriptions to RevenueCat for migration
  /// This should be called once per install after login to import existing subscriptions
  /// Uses SharedPreferences to ensure it only runs once
  /// 
  /// [accessToken] - The user's Supabase access token for backend verification
  /// 
  /// Returns true if sync was attempted (or already done), false on error
  Future<bool> syncPurchasesForMigration(String accessToken) async {
    if (!_isInitialized) {
      print('$_TAG Cannot sync - RevenueCat not initialized');
      return false;
    }
    
    try {
      // Check if migration sync has already been done
      final prefs = await SharedPreferences.getInstance();
      final alreadySynced = prefs.getBool(_migrationSyncedKey) ?? false;
      
      if (alreadySynced) {
        print('$_TAG Migration sync already completed, skipping');
        return true;
      }
      
      print('$_TAG Starting one-time migration sync...');
      
      // Restore purchases to import any existing subscriptions into RevenueCat
      final customerInfo = await Purchases.restorePurchases();
      _cachedCustomerInfo = customerInfo;
      
      print('$_TAG Migration restore completed. Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
      
      // If there are active entitlements, sync with backend
      if (customerInfo.entitlements.active.isNotEmpty) {
        final syncResult = await _syncPurchaseWithBackend(customerInfo, accessToken);
        
        if (syncResult['success'] == true) {
          print('$_TAG Migration sync successful');
        } else {
          print('$_TAG Migration sync to backend failed: ${syncResult['error']}');
          // Don't mark as synced if backend sync failed - will retry next time
          return false;
        }
      } else {
        print('$_TAG No active subscriptions to migrate');
      }
      
      // Mark migration as complete
      await prefs.setBool(_migrationSyncedKey, true);
      print('$_TAG Migration sync marked as complete');
      
      return true;
      
    } on PlatformException catch (e) {
      print('$_TAG Error during migration sync: ${e.message}');
      return false;
    } catch (e) {
      print('$_TAG Unexpected error during migration sync: $e');
      return false;
    }
  }
  
  /// Handle customer info updates from RevenueCat
  /// This is called automatically when subscription status changes
  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) {
    print('$_TAG Handling customer info update');
    print('$_TAG Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
    
    // Note: Backend sync should be triggered by purchase/restore methods
    // This listener is mainly for logging and UI updates
  }
  
  /// Sync purchase information with backend to update Supabase database
  /// This ensures the backend is aware of the user's subscription status
  /// 
  /// [customerInfo] - The RevenueCat customer info containing subscription data
  /// [accessToken] - The user's Supabase access token for authentication
  /// 
  /// Returns a map with 'success' (bool) and optional 'error' (String)
  Future<Map<String, dynamic>> _syncPurchaseWithBackend(
    CustomerInfo customerInfo,
    String accessToken,
  ) async {
    try {
      print('$_TAG Syncing purchase with backend...');
      
      // Extract subscription information
      String? membershipTier;
      String? subscriptionExpiresAt;
      String? productId;
      
      // Get the first active entitlement (RevenueCat typically uses "premium" or custom identifiers)
      if (customerInfo.entitlements.active.isNotEmpty) {
        final firstEntitlement = customerInfo.entitlements.active.values.first;
        productId = firstEntitlement.productIdentifier;
        
        // Map product ID to membership tier
        membershipTier = _mapProductIdToTier(productId);
        
        // Get expiration date
        final expirationDateString = firstEntitlement.expirationDate;
        if (expirationDateString != null && expirationDateString.isNotEmpty) {
          // Parse the date string and convert back to ISO format if needed
          try {
            final expirationDate = DateTime.parse(expirationDateString);
            subscriptionExpiresAt = expirationDate.toIso8601String();
          } catch (e) {
            print('$_TAG Error parsing expiration date: $e');
            subscriptionExpiresAt = expirationDateString; // Use as-is if parse fails
          }
        }
        
        print('$_TAG Subscription details: tier=$membershipTier, productId=$productId, expiresAt=$subscriptionExpiresAt');
      }
      
      if (membershipTier == null) {
        return {
          'success': false,
          'error': 'Could not determine membership tier from entitlements'
        };
      }
      
      // TODO: Update this URL to match your backend endpoint
      final String backendUrl = '${AppConstants.yourBackendBaseUrl}/api/payments/sync-revenuecat-purchase';
      
      print('$_TAG Sending sync request to: $backendUrl');
      
      // Make request to backend
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'membershipTier': membershipTier,
          'subscriptionExpiresAt': subscriptionExpiresAt,
          'productId': productId,
          'revenueCatAppUserId': _currentAppUserId,
          'platform': Platform.isIOS ? 'apple' : 'google',
        }),
      );
      
      print('$_TAG Backend response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          print('$_TAG Backend sync successful');
          return {'success': true};
        } else {
          print('$_TAG Backend sync failed: ${responseBody['error']}');
          return {
            'success': false,
            'error': responseBody['error'] ?? 'Unknown backend error'
          };
        }
      } else {
        print('$_TAG Backend sync failed with status ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error': 'Backend sync failed (HTTP ${response.statusCode})'
        };
      }
      
    } catch (e) {
      print('$_TAG Error syncing with backend: $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}'
      };
    }
  }
  
  /// Map RevenueCat product ID to internal membership tier
  String _mapProductIdToTier(String productId) {
    final productIdLower = productId.toLowerCase();
    
    if (productIdLower.contains('weekly')) {
      return 'premium_weekly';
    } else if (productIdLower.contains('yearly') || productIdLower.contains('annual')) {
      return 'premium_yearly';
    } else if (productIdLower.contains('monthly')) {
      return 'premium_monthly';
    }
    
    // Default to monthly if can't determine
    print('$_TAG WARNING: Could not determine tier from productId "$productId", defaulting to premium_monthly');
    return 'premium_monthly';
  }
  
  /// Get current customer info (cached or fetch fresh)
  Future<CustomerInfo?> getCustomerInfo({bool forceRefresh = false}) async {
    if (!_isInitialized) {
      print('$_TAG Cannot get customer info - RevenueCat not initialized');
      return null;
    }
    
    if (!forceRefresh && _cachedCustomerInfo != null) {
      return _cachedCustomerInfo;
    }
    
    try {
      _cachedCustomerInfo = await Purchases.getCustomerInfo();
      return _cachedCustomerInfo;
    } catch (e) {
      print('$_TAG Error fetching customer info: $e');
      return null;
    }
  }
  
  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final customerInfo = await getCustomerInfo();
    return customerInfo?.entitlements.active.isNotEmpty ?? false;
  }
  
  /// Get the current subscription tier (if any)
  Future<String?> getCurrentTier() async {
    final customerInfo = await getCustomerInfo();
    
    if (customerInfo == null || customerInfo.entitlements.active.isEmpty) {
      return null;
    }
    
    final firstEntitlement = customerInfo.entitlements.active.values.first;
    return _mapProductIdToTier(firstEntitlement.productIdentifier);
  }
  
  /// Reset initialization state (useful for logout/testing)
  void reset() {
    print('$_TAG [$environmentLabel] Resetting RevenueCat service');
    _isInitialized = false;
    _currentAppUserId = null;
    _cachedCustomerInfo = null;
  }
  
  /// Debug logging helper for customer info
  void _logCustomerInfo(CustomerInfo? info) {
    if (info == null) {
      print('$_TAG [$environmentLabel] Customer info is null');
      return;
    }
    
    print('$_TAG [$environmentLabel] === Customer Info Details ===');
    print('$_TAG [$environmentLabel] App User ID: ${info.originalAppUserId}');
    print('$_TAG [$environmentLabel] Active Entitlements: ${info.entitlements.active.keys.toList()}');
    
    if (info.entitlements.active.isNotEmpty) {
      for (var entry in info.entitlements.active.entries) {
        final entitlement = entry.value;
        print('$_TAG [$environmentLabel]   - ${entry.key}:');
        print('$_TAG [$environmentLabel]     Product ID: ${entitlement.productIdentifier}');
        print('$_TAG [$environmentLabel]     Expiry: ${entitlement.expirationDate}');
        print('$_TAG [$environmentLabel]     Will Renew: ${entitlement.willRenew}');
        print('$_TAG [$environmentLabel]     Is Active: ${entitlement.isActive}');
        print('$_TAG [$environmentLabel]     Period: ${entitlement.periodType}');
        print('$_TAG [$environmentLabel]     Store: ${entitlement.store}');
      }
    } else {
      print('$_TAG [$environmentLabel] No active entitlements');
    }
    
    print('$_TAG [$environmentLabel] All Product IDs: ${info.allPurchasedProductIdentifiers}');
    print('$_TAG [$environmentLabel] Latest Expiration: ${info.latestExpirationDate}');
    print('$_TAG [$environmentLabel] =============================');
  }
}

