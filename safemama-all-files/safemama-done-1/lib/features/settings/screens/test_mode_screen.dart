// lib/features/settings/screens/test_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safemama/core/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safemama/core/services/supabase_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:safemama/core/constants/app_constants.dart';

/// Test Mode Screen for debugging RevenueCat subscriptions
/// This screen is only accessible in debug builds
/// 
/// Features:
/// - Display current environment (Sandbox/Production)
/// - Show active entitlements and product IDs
/// - Display subscription expiry dates
/// - Show membership tier from backend
/// - Manual sync/restore buttons
/// - Test endpoint access for simulating purchases
class TestModeScreen extends StatefulWidget {
  const TestModeScreen({Key? key}) : super(key: key);

  @override
  State<TestModeScreen> createState() => _TestModeScreenState();
}

class _TestModeScreenState extends State<TestModeScreen> {
  final _revenueCat = RevenueCatService();
  CustomerInfo? _customerInfo;
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // Get RevenueCat customer info
      _customerInfo = await _revenueCat.getCustomerInfo(forceRefresh: true);

      // Get profile data from Supabase
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await SupabaseService.client
            .from('profiles')
            .select('membership_tier, subscription_expires_at, subscription_platform, last_purchase_product_id')
            .eq('id', userId)
            .single();
        _profileData = response;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading data: $e';
      });
    }
  }

  Future<void> _syncPurchases() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Syncing purchases...';
    });

    try {
      final accessToken = await SupabaseService.client.auth.currentSession?.accessToken;
      if (accessToken == null) throw Exception('Not authenticated');

      final result = await _revenueCat.restorePurchases(accessToken);

      setState(() {
        _isLoading = false;
        _statusMessage = result['success'] == true
            ? 'Sync successful!'
            : 'Sync failed: ${result['error']}';
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sync error: $e';
      });
    }
  }

  Future<void> _testPurchase(String productId) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Simulating test purchase via backend...';
    });

    try {
      final accessToken = await SupabaseService.client.auth.currentSession?.accessToken;
      if (accessToken == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${AppConstants.yourBackendBaseUrl}/api/internal/test-sync-revenuecat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'testProductId': productId,
        }),
      );

      final result = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
        _statusMessage = result['success'] == true
            ? 'Test purchase successful! Tier: ${result['membershipTier']}'
            : 'Test purchase failed: ${result['error']}';
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Test purchase error: $e';
      });
    }
  }

  Future<void> _resetToFree() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Resetting to free tier...';
    });

    try {
      final accessToken = await SupabaseService.client.auth.currentSession?.accessToken;
      if (accessToken == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${AppConstants.yourBackendBaseUrl}/api/internal/test-reset-to-free'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final result = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
        _statusMessage = result['success'] == true
            ? 'Reset to free tier successful!'
            : 'Reset failed: ${result['error']}';
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Reset error: $e';
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Mode - RevenueCat'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Environment Indicator
                  _buildEnvironmentCard(),
                  const SizedBox(height: 16),

                  // Status Message
                  if (_statusMessage != null) ...[
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                  ],

                  // RevenueCat Info
                  _buildRevenueCatCard(),
                  const SizedBox(height: 16),

                  // Backend Profile Info
                  _buildBackendCard(),
                  const SizedBox(height: 16),

                  // Actions
                  _buildActionsCard(),
                  const SizedBox(height: 16),

                  // Test Purchases (only in test mode)
                  if (_revenueCat.isTestMode) _buildTestPurchasesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildEnvironmentCard() {
    final isTestMode = _revenueCat.isTestMode;
    return Card(
      color: isTestMode ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isTestMode ? Icons.science : Icons.verified,
                  color: isTestMode ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _revenueCat.environmentLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isTestMode ? Colors.orange.shade900 : Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isTestMode
                  ? 'Using sandbox API keys and test product IDs'
                  : 'Using production API keys',
              style: TextStyle(
                color: isTestMode ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _statusMessage!.contains('successful') || _statusMessage!.contains('Sync successful')
          ? Colors.green.shade50
          : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _statusMessage!,
          style: TextStyle(
            color: _statusMessage!.contains('successful') || _statusMessage!.contains('Sync successful')
                ? Colors.green.shade900
                : Colors.red.shade900,
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCatCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RevenueCat Customer Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_customerInfo == null)
              const Text('No customer info available')
            else ...[
              _buildInfoRow('App User ID', _customerInfo!.originalAppUserId),
              _buildInfoRow('Active Entitlements',
                  _customerInfo!.entitlements.active.keys.join(', ').ifEmpty(() => 'None')),
              const SizedBox(height: 8),
              if (_customerInfo!.entitlements.active.isNotEmpty) ...[
                const Text(
                  'Entitlement Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...(_customerInfo!.entitlements.active.entries.map((e) {
                  final ent = e.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎯 ${e.key}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      _buildInfoRow('  Product ID', ent.productIdentifier),
                      _buildInfoRow('  Expiry', ent.expirationDate ?? 'N/A'),
                      _buildInfoRow('  Will Renew', ent.willRenew.toString()),
                      _buildInfoRow('  Store', ent.store.toString()),
                      const SizedBox(height: 8),
                    ],
                  );
                })),
              ],
              _buildInfoRow('All Product IDs',
                  _customerInfo!.allPurchasedProductIdentifiers.join(', ').ifEmpty(() => 'None')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackendCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Profile Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_profileData == null)
              const Text('No profile data available')
            else ...[
              _buildInfoRow('Membership Tier', _profileData!['membership_tier']?.toString() ?? 'N/A'),
              _buildInfoRow('Subscription Platform', _profileData!['subscription_platform']?.toString() ?? 'N/A'),
              _buildInfoRow('Subscription Expires At', _profileData!['subscription_expires_at']?.toString() ?? 'N/A'),
              _buildInfoRow('Last Product ID', _profileData!['last_purchase_product_id']?.toString() ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _syncPurchases,
              icon: const Icon(Icons.sync),
              label: const Text('Restore/Sync Purchases'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestPurchasesCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Backend Test Simulation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Simulate subscription sync via backend (no RevenueCat SDK call):',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _testPurchase('safemama_premium_weekly'),
              child: const Text('Backend Test: Weekly Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade300,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testPurchase('safemama_premium_monthly'),
              child: const Text('Backend Test: Monthly Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testPurchase('safemama_premium_yearly'),
              child: const Text('Backend Test: Yearly Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'For real RevenueCat Test Store testing, use the subscription screen in the app.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetToFree,
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Free Tier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(value),
              child: Text(
                value,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String ifEmpty(String Function() orElse) => isEmpty ? orElse() : this;
}
