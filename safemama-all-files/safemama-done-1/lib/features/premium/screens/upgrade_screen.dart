// lib/features/premium/screens/upgrade_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safemama/core/constants/app_constants.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/services/revenuecat_service.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/l10n/app_localizations.dart';

// Provider for RevenueCat offerings
final revenueCatOfferingsProvider = FutureProvider<Offering?>((ref) async {
  final revenueCatService = RevenueCatService();
  return await revenueCatService.getOfferings();
});

// Provider for selected package
final selectedPackageProvider = StateProvider<Package?>((ref) => null);

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Schedule initialization after the first frame to avoid
    // "dependOnInheritedWidgetOfExactType was called before initState completed" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _initializeRevenueCat();
      }
    });
  }

  Future<void> _initializeRevenueCat() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    final userId = ref.read(userProfileNotifierProvider).userId;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not logged in';
        });
      }
      return;
    }

    try {
      final revenueCatService = RevenueCatService();
      if (!revenueCatService.isInitialized) {
        await revenueCatService.initRevenueCat(userId);
      }
      // Refresh offerings after initialization
      if (mounted) {
        ref.invalidate(revenueCatOfferingsProvider);
      }
    } catch (e) {
      print('[UpgradeScreen] Error initializing RevenueCat: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize subscription service: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handlePurchase() async {
    final selectedPackage = ref.read(selectedPackageProvider);
    if (selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subscription plan')),
      );
      return;
    }

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final accessToken = ref.read(supabaseServiceProvider).client.auth.currentSession?.accessToken;
      if (accessToken == null) {
        throw Exception('Authentication error: Please log in again');
      }

      final revenueCatService = RevenueCatService();
      final result = await revenueCatService.purchasePackage(selectedPackage, accessToken);

      setState(() {
        _isPurchasing = false;
      });

      if (result['success'] == true) {
        // Reload user profile to reflect new subscription
        await ref.read(userProfileNotifierProvider.notifier).loadUserProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['warning'] ?? 'Subscription activated successfully!'),
              backgroundColor: result['warning'] != null ? Colors.orange : Colors.green,
            ),
          );
          
          // Navigate back or to success screen
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Purchase failed';
        });

        if (result['userCancelled'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      final accessToken = ref.read(supabaseServiceProvider).client.auth.currentSession?.accessToken;
      if (accessToken == null) {
        throw Exception('Authentication error: Please log in again');
      }

      final revenueCatService = RevenueCatService();
      final result = await revenueCatService.restorePurchases(accessToken);

      setState(() {
        _isRestoring = false;
      });

      if (result['success'] == true) {
        // Reload user profile to reflect restored subscription
        await ref.read(userProfileNotifierProvider.notifier).loadUserProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Purchases restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Restore failed';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    final offeringsAsync = ref.watch(revenueCatOfferingsProvider);
    final selectedPackage = ref.watch(selectedPackageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.buttonUpgradeToPremium),
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Icon(Icons.workspace_premium, size: 60, color: AppTheme.newPremiumGold),
              const SizedBox(height: 16),
              Text(
                "Unlock Your Ultimate Pregnancy Companion",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose a plan to get instant, personalized, and expert-backed guidance.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              // Error message display
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // Offerings Display
              offeringsAsync.when(
                data: (offering) {
                  if (offering == null || offering.availablePackages.isEmpty) {
                    return _buildErrorState(
                      'No subscription plans available',
                      'Please check your internet connection and try again.',
                      onRetry: () => ref.invalidate(revenueCatOfferingsProvider),
                    );
                  }

                  return _buildPackagesDisplay(offering.availablePackages, selectedPackage);
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorState(
                  'Failed to load subscription plans',
                  error.toString(),
                  onRetry: () => ref.invalidate(revenueCatOfferingsProvider),
                ),
              ),

              const SizedBox(height: 30),

              // Features List
              Text(
                S.premiumFeaturesInclude,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ..._buildFeaturesList(selectedPackage),

              const SizedBox(height: 30),

              // Purchase Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.newPremiumGold,
                  foregroundColor: Colors.black,
                ),
                onPressed: (selectedPackage == null || _isPurchasing || _isRestoring)
                    ? null
                    : _handlePurchase,
                child: _isPurchasing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(S.chooseYourPlanButton),
              ),

              const SizedBox(height: 12),

              // Restore Purchases Button
              TextButton(
                onPressed: (_isPurchasing || _isRestoring) ? null : _handleRestore,
                child: _isRestoring
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(S.restorePurchasesButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String title, String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.avoidRed),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: const Text("Retry"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesDisplay(List<Package> packages, Package? selectedPackage) {
    // Sort packages: weekly, monthly, yearly
    final sortedPackages = [...packages];
    sortedPackages.sort((a, b) {
      final aId = a.identifier.toLowerCase();
      final bId = b.identifier.toLowerCase();
      
      if (aId.contains('weekly')) return -1;
      if (bId.contains('weekly')) return 1;
      if (aId.contains('monthly')) return -1;
      if (bId.contains('monthly')) return 1;
      return 0;
    });

    // Display in horizontal scroll if more than 2 packages
    if (sortedPackages.length >= 3) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: sortedPackages.map((package) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SizedBox(
                width: 160,
                child: _buildPackageCard(package, selectedPackage == package),
              ),
            );
          }).toList(),
        ),
      );
    }

    // Otherwise, display in a row
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedPackages.map((package) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildPackageCard(package, selectedPackage == package),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPackageCard(Package package, bool isSelected) {
    final packageId = package.identifier.toLowerCase();
    final isWeekly = packageId.contains('weekly');
    final isYearly = packageId.contains('yearly') || packageId.contains('annual');

    String displayTitle = 'Monthly';
    String periodText = '/month';
    
    if (isWeekly) {
      displayTitle = 'Weekly';
      periodText = '/week';
    } else if (isYearly) {
      displayTitle = 'Yearly';
      periodText = '/year';
    }

    return GestureDetector(
      onTap: () {
        ref.read(selectedPackageProvider.notifier).state = package;
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryPurple.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  package.storeProduct.priceString,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  periodText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isYearly)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "BEST VALUE",
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFeaturesList(Package? selectedPackage) {
    final packageId = selectedPackage?.identifier.toLowerCase() ?? '';
    
    List<String> features;
    
    if (packageId.contains('weekly')) {
      features = [
        "${AppConstants.premiumWeeklyScanLimit} Product Scans / week",
        "${AppConstants.premiumWeeklyAskExpertLimit} 'Ask an Expert' Queries / week",
        "${AppConstants.premiumWeeklyManualSearchLimit} AI Manual Searches / week",
        "${AppConstants.premiumWeeklyGuideLimit} AI Personalized Guides / week",
        "${AppConstants.premiumWeeklyDocumentAnalysisLimit} Document Analysis / week",
        "${AppConstants.premiumWeeklyPregnancyTestAILimit} Pregnancy Test AI / week",
        "✨ All Premium Pregnancy Tools ✨",
        "Full Scan History",
        "Access Premium Content",
      ];
    } else if (packageId.contains('yearly') || packageId.contains('annual')) {
      features = [
        "✨ UNLIMITED Scans ✨ (1000/year)",
        "${AppConstants.premiumYearlyAskExpertLimit} 'Ask an Expert' Queries / year",
        "${AppConstants.premiumYearlyManualSearchLimit} AI Manual Searches / year",
        "${AppConstants.premiumYearlyGuideLimit} AI Personalized Guides / year",
        "${AppConstants.premiumYearlyDocumentAnalysisLimit} Document Analysis / year",
        "${AppConstants.premiumYearlyPregnancyTestAILimit} Pregnancy Test AI / year",
        "✨ All Premium Pregnancy Tools ✨",
        "Unlimited Scan History",
        "Access All Premium Content",
      ];
    } else {
      // Default to monthly
      features = [
        "${AppConstants.premiumMonthlyScanLimit} Product Scans / month",
        "${AppConstants.premiumMonthlyAskExpertLimit} 'Ask an Expert' Queries / month",
        "${AppConstants.premiumMonthlyManualSearchLimit} AI Manual Searches / month",
        "${AppConstants.premiumMonthlyGuideLimit} AI Personalized Guides / month",
        "${AppConstants.premiumMonthlyDocumentAnalysisLimit} Document Analysis / month",
        "${AppConstants.premiumMonthlyPregnancyTestAILimit} Pregnancy Test AI / month",
        "✨ All Premium Pregnancy Tools ✨",
        "Unlimited Scan History",
        "Access All Premium Content",
      ];
    }

    return features.map((feature) => _buildFeatureItem(feature)).toList();
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: AppTheme.newCheckGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(feature, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
