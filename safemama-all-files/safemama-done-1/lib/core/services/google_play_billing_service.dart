import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:safemama/core/constants/app_constants.dart';

// Google Play Store subscription product IDs
// These MUST match the exact IDs you set up in Google Play Console
const String weeklyProductId = 'safemama_premium_weekly';
const String monthlyProductId = 'safemama_premium_monthly';
const String yearlyProductId = 'safemama_premium_yearly';

const Set<String> googlePlayProductIds = {
  weeklyProductId,
  monthlyProductId,
  yearlyProductId,
};

/// Google Play Billing service for handling Android subscriptions
/// This wraps the in_app_purchase plugin specifically for Google Play Store
class GooglePlayBillingService with ChangeNotifier {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GooglePlayBillingService(this._ref) {
    _initialize();
  }

  void _initialize() {
    print("[GooglePlayBilling] Initializing...");
    
    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        print("[GooglePlayBilling] Purchase stream done.");
        _subscription.cancel();
      },
      onError: (error) {
        print("[GooglePlayBilling] Error on purchase stream: $error");
        _handleError(error.toString());
      },
    );
    
    _checkAvailabilityAndLoadProducts();
  }

  Future<void> _checkAvailabilityAndLoadProducts() async {
    _isAvailable = await _iap.isAvailable();
    print("[GooglePlayBilling] Google Play Store available: $_isAvailable");
    
    if (_isAvailable) {
      await _loadProducts();
    } else {
      _handleError("Google Play Store is not available on this device.");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    print("[GooglePlayBilling] Loading products for IDs: $googlePlayProductIds");
    
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(googlePlayProductIds);
      
      if (response.error != null) {
        _handleError(response.error!.message);
        _products = [];
      } else if (response.productDetails.isEmpty) {
        _handleError("No products found. Check your Product IDs in Google Play Console.");
        _products = [];
      } else {
        // Sort products: weekly, monthly, then yearly
        _products = response.productDetails..sort((a, b) {
          if (a.id == weeklyProductId) return -1;
          if (b.id == weeklyProductId) return 1;
          if (a.id == monthlyProductId) return -1;
          if (b.id == monthlyProductId) return 1;
          return 0;
        });
        
        print("[GooglePlayBilling] Found ${_products.length} products:");
        for (var product in _products) {
          print("  - ${product.id}: ${product.title} - ${product.price}");
        }
        
        _errorMessage = null;
      }
    } catch (e) {
      _handleError("Failed to load products: ${e.toString()}");
    }
    
    notifyListeners();
  }

  /// Start the purchase flow for a given product
  Future<void> buySubscription(ProductDetails productDetails) async {
    print("[GooglePlayBilling] Starting purchase for: ${productDetails.id}");
    
    if (!_isAvailable) {
      _handleError("Google Play Store is not available.");
      return;
    }

    try {
      // For subscriptions, we need to use the proper purchase parameter
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      
      // Buy non-consumable product (subscriptions are non-consumable)
      bool purchaseResult = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!purchaseResult) {
        print("[GooglePlayBilling] Purchase initiation failed");
        _handleError("Failed to start purchase flow.");
      } else {
        print("[GooglePlayBilling] Purchase flow started successfully");
      }
    } catch (e) {
      print("[GooglePlayBilling] Error buying product: ${e.toString()}");
      _handleError("Purchase error: ${e.toString()}");
    }
  }

  /// Restore previous purchases (useful if user reinstalls app)
  Future<void> restorePurchases() async {
    print("[GooglePlayBilling] Restoring purchases...");
    
    try {
      await _iap.restorePurchases();
      print("[GooglePlayBilling] Restore purchases initiated");
    } catch (e) {
      print("[GooglePlayBilling] Error restoring purchases: ${e.toString()}");
      _handleError("Failed to restore purchases: ${e.toString()}");
    }
  }

  void _handleError(String errorMsg) {
    _errorMessage = errorMsg;
    print("[GooglePlayBilling] ERROR: $_errorMessage");
    notifyListeners();
  }

  /// Listen to purchase updates and verify with backend
  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print("[GooglePlayBilling] Purchase update: ${purchaseDetails.productID} - Status: ${purchaseDetails.status}");
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending state (e.g., waiting for user to complete payment)
        print("[GooglePlayBilling] Purchase pending: ${purchaseDetails.productID}");
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print("[GooglePlayBilling] Purchase error: ${purchaseDetails.error?.message}");
          _handleError(purchaseDetails.error?.message ?? "Purchase failed");
        } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                   purchaseDetails.status == PurchaseStatus.restored) {
          // Verify the purchase with the backend
          bool valid = await _verifyPurchaseWithBackend(purchaseDetails);
          
          if (valid) {
            print("[GooglePlayBilling] Purchase valid. Delivering content for ${purchaseDetails.productID}.");
            // Reload user profile to reflect the updated subscription status
            await _ref.read(userProfileNotifierProvider.notifier).loadUserProfile();
          } else {
            print("[GooglePlayBilling] Purchase verification failed.");
          }
        }
        
        // Always complete the purchase to remove it from the queue
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
          print("[GooglePlayBilling] Purchase completed for: ${purchaseDetails.productID}");
        }
      }
    }
  }

  /// Verify the purchase with the backend
  Future<bool> _verifyPurchaseWithBackend(PurchaseDetails purchaseDetails) async {
    print("[GooglePlayBilling] Verifying purchase with backend for product: ${purchaseDetails.productID}");

    // Get the authentication token
    final String? accessToken = _ref.read(supabaseServiceProvider).client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      print("[GooglePlayBilling] No auth token available. Cannot verify purchase.");
      _handleError("Authentication error: Please log in.");
      return false;
    }

    try {
      // Get purchase token from Android-specific purchase details
      String purchaseToken = '';
      if (purchaseDetails is GooglePlayPurchaseDetails) {
        purchaseToken = purchaseDetails.billingClientPurchase.purchaseToken;
      } else {
        print("[GooglePlayBilling] WARNING: PurchaseDetails is not GooglePlayPurchaseDetails");
        purchaseToken = purchaseDetails.verificationData.serverVerificationData;
      }

      // Construct the URL to the backend's Google Play verification endpoint
      final String verificationEndpoint = '${AppConstants.yourBackendBaseUrl}/api/payments/verify-google-play';
      
      print("[GooglePlayBilling] Sending verification request to: $verificationEndpoint");
      
      // Make an HTTP POST request to the backend
      final response = await http.post(
        Uri.parse(verificationEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'productId': purchaseDetails.productID,
          'purchaseToken': purchaseToken,
        }),
      );

      print("[GooglePlayBilling] Backend response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          print("[GooglePlayBilling] Backend successfully verified purchase and updated user plan.");
          print("[GooglePlayBilling] New membership tier: ${responseBody['membershipTier']}");
          print("[GooglePlayBilling] Subscription expires at: ${responseBody['subscriptionExpiresAt']}");
          return true;
        } else {
          print("[GooglePlayBilling] Backend failed to verify purchase: ${responseBody['error'] ?? 'Unknown error'}");
          _handleError(responseBody['error'] ?? "Purchase verification failed.");
          return false;
        }
      } else {
        print("[GooglePlayBilling] Backend verification request failed. Status: ${response.statusCode}, Body: ${response.body}");
        _handleError("Purchase could not be verified, please contact support.");
        return false;
      }
    } catch (e) {
      print("[GooglePlayBilling] Exception during backend purchase verification: $e");
      _handleError("Network error during purchase verification: ${e.toString()}");
      return false;
    }
  }

  @override
  void dispose() {
    print("[GooglePlayBilling] Disposing...");
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider for the Google Play Billing service
final googlePlayBillingServiceProvider = ChangeNotifierProvider<GooglePlayBillingService>((ref) {
  return GooglePlayBillingService(ref);
});

