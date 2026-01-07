import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:safemama/core/providers/app_providers.dart';

// ADD THESE NEW IMPORTS
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:safemama/core/constants/app_constants.dart'; // For your backend URL

// These are the Product IDs you created in App Store Connect.
const String _monthlyProductID = 'premium_monthly';
const String _yearlyProductID = 'SafeMama_Premium_Yearly';
const Set<String> _productIds = {_monthlyProductID, _yearlyProductID};

class IapService with ChangeNotifier {
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

  IapService(this._ref) {
    _initialize();
  }

  void _initialize() {
    print("[IapService] Initializing...");
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        print("[IapService] Purchase stream done.");
        _subscription.cancel();
      },
      onError: (error) {
        print("[IapService] Error on purchase stream: $error");
        _handleError(error.toString());
      },
    );
    _checkAvailabilityAndLoadProducts();
  }

  Future<void> _checkAvailabilityAndLoadProducts() async {
    _isAvailable = await _iap.isAvailable();
    print("[IapService] Store available: $_isAvailable");
    if (_isAvailable) {
      await _loadProducts();
    } else {
      _handleError("The App Store is not available on this device.");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    print("[IapService] Loading products for IDs: $_productIds");
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        _handleError(response.error!.message);
        _products = [];
      } else if (response.productDetails.isEmpty) {
        _handleError("No products found. Check your Product IDs in App Store Connect.");
        _products = [];
      } else {
        // Sort products: yearly first, then monthly
        _products = response.productDetails..sort((a, b) => a.id == _yearlyProductID ? -1 : 1);
        print("[IapService] Found ${_products.length} products.");
        _errorMessage = null;
      }
    } catch (e) {
      _handleError("Failed to load products: ${e.toString()}");
    }
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
      // For subscriptions on iOS, you might use buyNonConsumable, but buyConsumable
      // is often used to simplify the logic of re-purchasing. The backend verification
      // is what truly matters for subscriptions.
    } catch (e) {
       print("[IapService] Error buying product: ${e.toString()}");
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
       print("[IapService] Error restoring purchases: ${e.toString()}");
    }
  }

  void _handleError(String errorMsg) {
    _errorMessage = errorMsg;
    print("[IapService] ERROR: $_errorMessage");
    notifyListeners();
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending state if needed (e.g., show a loading indicator)
        print("[IapService] Purchase pending: ${purchaseDetails.productID}");
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print("[IapService] Purchase error: ${purchaseDetails.error?.message}");
          // If there's an error and it's StoreKit related, you might want to specifically log it
          // StoreKit errors can occur if a product is unavailable in a region,
          // if there's a device issue, or sometimes due to App Store Connect setup problems.
        } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
          // This is the CRUCIAL call to your backend
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            print("[IapService] Purchase valid. Delivering content for ${purchaseDetails.productID}.");
            // Here you unlock the premium content.
            // The backend's /upgrade-user-plan endpoint already handles updating the user's tier.
            // So, after successful verification, we just need to reload the user profile
            // to reflect the updated status from the database.
            await _ref.read(userProfileNotifierProvider.notifier).loadUserProfile();
          } else {
            print("[IapService] Purchase NOT valid.");
            // If backend verification fails, do NOT deliver content
          }
        }
        // Always complete the purchase after handling it, regardless of success/failure
        // This clears the transaction queue on the device.
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
          print("[IapService] Purchase completed for: ${purchaseDetails.productID}");
        }
      }
    }
  }

  // THIS IS THE CORRECTED _verifyPurchase FUNCTION
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    print("[IapService] Verifying purchase with backend for product: ${purchaseDetails.productID}");

    // Get the authentication token for your user (assuming Supabase authentication)
    final String? accessToken = _ref.read(supabaseServiceProvider).client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      print("[IapService] No auth token available. Cannot verify purchase.");
      _handleError("Authentication error: Please log in.");
      return false;
    }

    try {
      // Construct the URL to your backend's receipt verification endpoint
      final String verificationEndpoint = '${AppConstants.yourBackendBaseUrl}/api/payments/verify-apple-receipt';
      
      // Make an HTTP POST request to your backend
      final response = await http.post(
        Uri.parse(verificationEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Send the user's auth token
        },
        body: jsonEncode({
          'receiptData': purchaseDetails.verificationData.serverVerificationData, // Send the raw receipt data
          // Optionally, you could send purchaseDetails.productID if your backend needs it explicitly here
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          print("[IapService] Backend successfully verified receipt and updated user plan.");
          // Backend has updated the user's profile in the database.
          // The `_listenToPurchaseUpdated` method will call `loadUserProfile` after this returns true.
          return true;
        } else {
          print("[IapService] Backend failed to verify receipt: ${responseBody['error'] ?? 'Unknown error from backend'}");
          _handleError(responseBody['error'] ?? "Payment verification failed.");
          return false;
        }
      } else {
        print("[IapService] Backend verification request failed. Status: ${response.statusCode}, Body: ${response.body}");
        _handleError("Payment verification failed on server (Status: ${response.statusCode}).");
        return false;
      }
    } catch (e) {
      print("[IapService] Exception during backend receipt verification: $e");
      // Provide a user-friendly error message for network/unexpected issues
      _handleError("Network error during payment verification: ${e.toString()}");
      return false;
    }
  }

  @override
  void dispose() {
    print("[IapService] Disposing...");
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }
}