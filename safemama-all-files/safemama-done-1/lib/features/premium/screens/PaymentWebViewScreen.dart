// lib/features/premium/screens/payment_webview_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/constants/app_colors.dart'; // Assuming AppColors.primary exists
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends ConsumerStatefulWidget {
final String checkoutUrl; // The URL from Dodo Payments (e.g., https://checkout.dodopayments.com/...)

const PaymentWebViewScreen({super.key, required this.checkoutUrl});

@override
ConsumerState<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
late final WebViewController _controller;
bool _isLoadingPage = true;
// Your app's custom scheme and host for the success redirect
final String _appScheme = "com.safemama.app";
final String _successHost = "payment-success";

@override
void initState() {
super.initState();
print("[PaymentWebViewScreen] Initializing with URL: ${widget.checkoutUrl}");

_controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setBackgroundColor(const Color(0x00000000)) // Transparent background
  ..setNavigationDelegate(
    NavigationDelegate(
      onProgress: (int progress) {
        print("[PaymentWebViewScreen] WebView loading progress: $progress%");
      },
      onPageStarted: (String url) {
        print("[PaymentWebViewScreen] WebView page started loading: $url");
        if (mounted) setState(() => _isLoadingPage = true);
      },
      onPageFinished: (String url) {
        print("[PaymentWebViewScreen] WebView page finished loading: $url");
        if (mounted) setState(() => _isLoadingPage = false);
      },
      onWebResourceError: (WebResourceError error) {
        // CORRECTED Line:
        print("[PaymentWebViewScreen] WebView error: ${error.description} (Code: ${error.errorCode}, Type: ${error.errorType}) for URL: ${error.url}. Is for main frame: ${error.isForMainFrame}");
        
        if (mounted) setState(() => _isLoadingPage = false);
        // Optionally show an error message to the user within the WebView screen
        // For example, if it's a critical error loading the initial payment page:
        if (error.isForMainFrame == true) { // Check if isForMainFrame is true (it's nullable bool)
          // It's good practice to check if context is still valid if showing UI elements
          if (mounted && context.findRenderObject() != null && context.findRenderObject()!.attached) { 
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)?.paymentPageLoadError ?? "Failed to load payment page. Please check connection.")) // Add to l10n
            );
            // Consider popping if the main payment page itself fails to load
            // if (context.canPop()) context.pop(); 
          }
        }
      },
      onNavigationRequest: (NavigationRequest request) {
        print("[PaymentWebViewScreen] WebView navigating to: ${request.url}");
        final Uri uri = Uri.parse(request.url);

        // Check if this is our app's custom scheme redirect
        if (uri.scheme == _appScheme && uri.host == _successHost) {
          print("[PaymentWebViewScreen] Detected app scheme redirect: ${request.url}");
          // Extract parameters
          final String? paymentId = uri.queryParameters['payment_id'];
          final String? status = uri.queryParameters['status'];
          final String? orderId = uri.queryParameters['order_id']; 
          
          print("[PaymentWebViewScreen] Extracted from redirect: PaymentID: $paymentId, Status: $status, OrderID: $orderId");

          // IMPORTANT: Close the WebView screen *before* navigating to PaymentStatusScreen
          // to prevent building PaymentStatusScreen on top of the WebView stack.
          // We use pushReplacement to ensure PaymentStatusScreen replaces the UpgradeScreen
          // (or whichever screen launched the WebView).
          // First, pop this WebView screen:
          if (context.canPop()) {
             // No, we want to replace the screen that LAUNCHED the webview.
             // So, we should use pushReplacement on the route that called this webview.
             // For now, let's just pop this and then handle the navigation where this was pushed from.
             // Better: Use GoRouter to navigate to the payment status screen, replacing the current route stack
             // up to a certain point or just replacing this one.
          }

          // Navigate to PaymentStatusScreen using GoRouter and replace the WebView
          // This will correctly use your AppRouter's logic.
          // We use context.go to potentially replace the whole stack up to where /upgrade was,
          // or use context.pushReplacement if we know this WebView was pushed simply.
          // For a payment flow, replacing is often good.
          
          // Construct the path with query parameters for GoRouter
          final Map<String, String> queryParams = {};
          if (paymentId != null) queryParams['payment_id'] = paymentId;
          if (status != null) queryParams['status'] = status;
          if (orderId != null) queryParams['order_id'] = orderId;

          final paymentStatusUri = Uri(
            path: AppRouter.paymentSuccessCallbackPath, // Just the path, e.g., "/payment-success"
            queryParameters: queryParams.isNotEmpty ? queryParams : null,
          );
          
          // Replace current WebView screen with PaymentStatusScreen
          // This assumes PaymentWebViewScreen was pushed onto the stack.
          // If PaymentWebViewScreen itself is a top-level route, context.go would be more appropriate.
          // Let's use pushReplacement for now from this specific context.
          // GoRouter.of(context).pushReplacement(paymentStatusUri.toString()); // This will use relative path logic
          
          // Better: Use the named route and pass query params via `extra` if `PaymentStatusScreen` is designed for it,
          // or ensure GoRouter handles query params for the path.
          // Your current PaymentStatusScreen gets params from state.uri.queryParameters, so this is fine:
          GoRouter.of(context).replace(paymentStatusUri.toString());


          return NavigationDecision.prevent; // Prevent the WebView from actually loading com.safemama.app://...
        }
        return NavigationDecision.navigate; // Allow other navigations (within Dodo's site)
      },
    ),
  )
  ..loadRequest(Uri.parse(widget.checkoutUrl));


}

@override
Widget build(BuildContext context) {
final S = AppLocalizations.of(context)!;
return Scaffold(
appBar: AppBar(
title: Text(S.paymentGatewayTitle), // Add to l10n: "Secure Payment"
leading: IconButton(
icon: const Icon(Icons.close),
onPressed: () {
// Ask user for confirmation before closing payment process
showDialog(
context: context,
builder: (dialogContext) => AlertDialog(
title: Text(S.paymentCancelConfirmTitle), // "Cancel Payment?"
content: Text(S.paymentCancelConfirmMsg), // "Are you sure you want to cancel the payment process?"
actions: [
TextButton(
child: Text(S.commonDialogNo), // "No"
onPressed: () => Navigator.of(dialogContext).pop(),
),
TextButton(
child: Text(S.commonDialogYes), // "Yes"
onPressed: () {
Navigator.of(dialogContext).pop(); // Close dialog
if (context.canPop()) context.pop(); // Close WebView screen
},
),
],
),
);
},
),
),
body: Stack(
children: [
WebViewWidget(controller: _controller),
if (_isLoadingPage)
const Center(
child: CircularProgressIndicator(color: AppColors.primary), // Assuming AppColors.primary is defined
),
],
),
);
}
}