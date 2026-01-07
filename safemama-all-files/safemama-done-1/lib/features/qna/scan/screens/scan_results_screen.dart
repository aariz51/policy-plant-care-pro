// lib/features/scan/screens/scan_results_screen.dart

import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/models/scan_data.dart';
import 'package:safemama/core/services/scan_history_service.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/constants/app_constants.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import 'package:safemama/core/widgets/premium_feature_wrapper.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
// import 'package:safemama/features/premium/screens/upgrade_screen.dart'; // Not directly used here, PaywallDialog handles upgrade navigation

class ScanResultsScreen extends ConsumerStatefulWidget {
  final String? scanId;
  final ScanData? scanData;

  const ScanResultsScreen({
    super.key,
    this.scanId,
    this.scanData,
  }) : assert(scanId != null || scanData != null,
               'Either scanId or scanData must be provided to ScanResultsScreen, or it must be loaded via GoRouter extra.');

  @override
  ConsumerState<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends ConsumerState<ScanResultsScreen> {
  ScanData? _displayableScanData;
  bool _isLoading = true; // Initialize to true
  String? _errorMessage;

  bool _isBookmarked = false;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true; // Ensure loading state is true at the beginning

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final goRouterState = GoRouterState.of(context);
      final dynamic extraData = goRouterState.extra;
      
      // ADDED DEBUG LOGGING BLOCK as per instructions
      print("----------------------------------------------------------------");
      print("[ScanResultsScreen initState] RAW extra data: $extraData");
      print("[ScanResultsScreen initState] RAW extra data RUNTIME TYPE: ${extraData?.runtimeType}");
      print("----------------------------------------------------------------");
      // END OF ADDED DEBUG LOGGING BLOCK

      final S = AppLocalizations.of(context);

      // Also log widget parameters for full context (Kept this existing useful log)
      print("[ScanResultsScreen initState] Initial widget.scanId: ${widget.scanId}, widget.scanData provided: ${widget.scanData != null}");

      bool dataLoadInitiated = false;

      if (extraData is String && extraData.isNotEmpty) {
        print("[ScanResultsScreen initState] Using scanId from GoRouter extra: $extraData");
        _fetchScanDataById(extraData);
        dataLoadInitiated = true;
      } else if (extraData is ScanData) {
        print("[ScanResultsScreen initState] Using ScanData directly from GoRouter extra.");
        if (mounted) {
          setState(() {
            _displayableScanData = extraData;
            _isLoading = false; // Data is available, stop loading
            _errorMessage = null;
          });
          _performPostLoadLogic(extraData);
        }
        dataLoadInitiated = true; // Data is handled
      } else {
        // This 'else' block addresses the case where 'extraData' is not a usable String ID or ScanData.
        // ADDED/MODIFIED print from instructions
        print("[ScanResultsScreen initState] ERROR: Invalid or missing scanId in extra.");
        
        if (extraData != null) {
            print("[ScanResultsScreen initState] Detailed: GoRouter extra was not a String or ScanData, got ${extraData.runtimeType}. Will attempt to use widget parameters.");
        } else {
            print("[ScanResultsScreen initState] Detailed: GoRouter extra is null. Will attempt to use widget parameters.");
        }
        // No navigation here; proceed to fallbacks. The "showing error" part is handled if fallbacks also fail.
      }

      // If data wasn't loaded/handled by GoRouter's 'extra'
      if (!dataLoadInitiated) {
        print("[ScanResultsScreen initState] GoRouter extra did not provide valid data or was null/invalid type. Falling back to widget parameters.");
        if (widget.scanData != null) {
          print("[ScanResultsScreen initState] Using widget.scanData.");
          if (mounted) {
            setState(() {
              _displayableScanData = widget.scanData;
              _isLoading = false; // Data is available, stop loading
              _errorMessage = null;
            });
            _performPostLoadLogic(widget.scanData!);
          }
          dataLoadInitiated = true; // Data is handled
        } else if (widget.scanId != null && widget.scanId!.isNotEmpty) {
          print("[ScanResultsScreen initState] Using widget.scanId: ${widget.scanId}");
          _fetchScanDataById(widget.scanId!);
          dataLoadInitiated = true;
        }
      }

      // If no data loading was initiated by any means
      if (!dataLoadInitiated) {
        print("[ScanResultsScreen initState] Error: No valid scanId or ScanData found from GoRouter extra or widget parameters.");
        if (mounted) {
          setState(() {
            _isLoading = false; // Stop loading
            _errorMessage = S?.scanResultErrorNoIdDetails ?? "Could not load scan results: Invalid or missing scan information.";
          });
        }
      }
    });
  }

  Future<void> _fetchScanDataById(String id) async {
    // Ensure isLoading is true if not already set by initState logic before calling this.
    // However, initState sets _isLoading = true initially, and this function is called from there.
    // If called from elsewhere, ensure _isLoading is managed.
    if(!mounted) return;
    if (!_isLoading) { // If somehow fetch is called when not loading, set it to loading.
        if (mounted) setState(() => _isLoading = true);
    }

    try {
      final scanHistoryService = ref.read(scanHistoryServiceProvider);
      final data = await scanHistoryService.fetchScanById(id);
      if (!mounted) return;

      if (data != null) {
        if (mounted) {
          setState(() {
            _displayableScanData = data;
            _isLoading = false;
            _errorMessage = null;
          });
        }
        _performPostLoadLogic(data);
      } else {
        final l10n = AppLocalizations.of(context);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = l10n?.scanNotFound ?? 'Scan not found.';
          });
        }
      }
    } catch (e, st) {
      if (!mounted) return;
      print("[ScanResultsScreen _fetchScanDataById] Error: $e, Stacktrace: $st");
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n?.genericErrorLoadingScan ?? 'Error loading scan details.';
        });
      }
    }
  }

  void _performPostLoadLogic(ScanData scanData) {
    if (!mounted) return;
    setState(() {
      _isBookmarked = scanData.isBookmarked;
    });
    print("[ScanResultsScreen _performPostLoadLogic] Using ScanData ID: ${scanData.id}, Product: ${scanData.productName}, Bookmarked: ${scanData.isBookmarked}");
  }

  Map<String, dynamic> _getRiskLevelStyle(RiskLevel level, AppLocalizations l10n) {
     switch (level) {
       case RiskLevel.safe:
         return {
           'text': l10n.riskLevelSafe,
           'color': AppTheme.safeGreen,
           'icon': Icons.check_circle_outline,
           'bannerColor': AppTheme.safeGreen.withOpacity(0.1)
         };
       case RiskLevel.caution:
         return {
           'text': l10n.riskLevelCaution,
           'color': AppTheme.warningOrange,
           'icon': Icons.warning_amber_rounded,
           'bannerColor': AppTheme.lightYellowBackground
         };
       case RiskLevel.avoid:
         return {
           'text': l10n.riskLevelAvoid,
           'color': AppTheme.avoidRed,
           'icon': Icons.dangerous_outlined,
           'bannerColor': AppTheme.avoidRed.withOpacity(0.1)
         };
       default:
         return {
           'text': l10n.riskLevelUnknown,
           'color': AppTheme.textSecondary,
           'icon': Icons.help_outline,
           'bannerColor': AppTheme.dividerColor.withOpacity(0.5)
         };
     }
   }

  String _getRiskBannerMessage(RiskLevel level, AppLocalizations l10n) {
    switch (level) {
      case RiskLevel.safe:
        return l10n.riskBannerSafeMessage;
      case RiskLevel.caution:
        return l10n.riskBannerCautionMessage;
      case RiskLevel.avoid:
        return l10n.riskBannerAvoidMessage;
      default:
        return l10n.riskBannerUnknownMessage;
    }
  }

  void _showPaywall(BuildContext context, String featureName) {
    final S = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CustomPaywallDialog(
          title: S.premiumFeatureDialogTitle(featureName),
          message: S.premiumFeatureDialogMessage(featureName),
          icon: Icons.article_outlined,
          iconColor: AppTheme.newPremiumGold,
        );
      },
    );
  }

  Future<void> _toggleBookmark() async {
    final ScanData? scanDataAtStart = _displayableScanData;
    final S = AppLocalizations.of(context)!; 

    if (scanDataAtStart == null) {
      print("[ScanResultsScreen _toggleBookmark] _displayableScanData is null. Returning.");
      return;
    }

    if (scanDataAtStart.isFromManualSearch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.bookmarkingNotAvailableForSearch ?? 'Bookmarking from search is not available yet.')),
      );
      return;
    }
    
    if (scanDataAtStart.id == null) {
        print("[ScanResultsScreen _toggleBookmark] Scan ID is null for a non-manual search item. Returning.");
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(S.errorToggleBookmark ?? 'Failed to update bookmark: Missing scan ID.')),
        );
        return;
    }

    if (!mounted) return;

    final String? nullableUserId = ref.read(userProfileNotifierProvider).userId;
    if (nullableUserId == null || nullableUserId.isEmpty) {
      print("Error: User ID is null or empty in ScanResultsScreen's _toggleBookmark.");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.errorUserNotAuthenticated), backgroundColor: AppTheme.avoidRed));
      return;
    }
    final String currentUserId = nullableUserId;

    setState(() => _isProcessingAction = true);

    final bool newBookmarkState = !scanDataAtStart.isBookmarked;

    if (mounted) {
      setState(() {
        _displayableScanData = scanDataAtStart.copyWith(isBookmarked: newBookmarkState);
        _isBookmarked = newBookmarkState; 
      });
    }

    try {
      final scanHistoryService = ref.read(scanHistoryServiceProvider);
      await scanHistoryService.markScanAsBookmarked(scanDataAtStart.id!, currentUserId, newBookmarkState);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newBookmarkState
              ? (S.itemBookmarkedSuccessfully ?? 'Item bookmarked successfully!')
              : (S.itemUnbookmarkedSuccessfully ?? 'Item unbookmarked successfully!')),
          backgroundColor: newBookmarkState ? AppTheme.safeGreen : AppTheme.primaryBlue,
        ),
      );

    } catch (e) {
      print("[ScanResultsScreen] Error toggling bookmark: $e");
      if (mounted) {
        setState(() {
          _displayableScanData = scanDataAtStart; 
          _isBookmarked = scanDataAtStart.isBookmarked; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.errorToggleBookmark ?? 'Failed to update bookmark.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }


  Future<XFile?> _getImageToShare(AppLocalizations l10n, ScanData scanData) async {
    String? imagePathToUse;

    if (scanData.scannedImagePath != null && scanData.scannedImagePath!.isNotEmpty && !scanData.scannedImagePath!.startsWith('http')) {
      imagePathToUse = scanData.scannedImagePath!;
    } else if (scanData.imageUrl != null && scanData.imageUrl!.startsWith('http')) {
       try {
        final response = await http.get(Uri.parse(scanData.imageUrl!));
        if (response.statusCode == 200) {
          final directory = await getTemporaryDirectory();
          final String fileNameBase = scanData.imageUrl!.split('/').last.split('?').first;
          String fileExtension = '.jpg';
          if (fileNameBase.contains('.')) {
              final ext = fileNameBase.split('.').last.toLowerCase();
              if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
                  fileExtension = '.$ext';
              }
          }
          final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_share$fileExtension';
          final filePath = '${directory.path}/$uniqueFileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          return XFile(file.path);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorDownloadingImageForShare), backgroundColor: AppTheme.avoidRed));
        }
      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorDownloadingImageForShare), backgroundColor: AppTheme.avoidRed));
      }
      return null;
    }

    if (imagePathToUse != null) {
      final file = File(imagePathToUse);
      if (await file.exists()) {
        return XFile(file.path);
      }
    }
    return null;
  }


  Future<void> _shareWithDoctor() async {
    final scanData = _displayableScanData;
    if (!mounted || scanData == null) return;

    if (mounted) setState(() => _isProcessingAction = true);
    final l10n = AppLocalizations.of(context)!;
    final riskStyleInfo = _getRiskLevelStyle(scanData.riskLevel, l10n);
    String localizedRiskText = riskStyleInfo['text'];
    
    // Build share message with app links and deep link
    final StringBuffer textToShare = StringBuffer();
    textToShare.writeln("*${l10n.scanResultSubject(scanData.productName)}*");
    textToShare.writeln("-----------------------------");
    textToShare.writeln("${l10n.productLabel}: ${scanData.productName}");
    textToShare.writeln("${l10n.riskLevelLabel}: $localizedRiskText");
    textToShare.writeln("${l10n.explanationLabel}: ${scanData.explanation.isNotEmpty ? scanData.explanation : l10n.notAvailable}");
    if (scanData.consumptionAdvice != null && scanData.consumptionAdvice!.isNotEmpty) {
      textToShare.writeln("${l10n.consumptionAdviceLabel}: ${scanData.consumptionAdvice}");
    }
    if (scanData.alternatives != null && scanData.alternatives!.isNotEmpty) {
       textToShare.writeln("${l10n.saferAlternativesLabel}: ${scanData.alternatives!.join(', ')}");
    }
    textToShare.writeln("${l10n.generalTipLabel}: ${scanData.pregnancyTip.isNotEmpty ? scanData.pregnancyTip : l10n.notAvailable}");
    textToShare.writeln("-----------------------------");
    textToShare.writeln("\n📱 Get SafeMama - AI Pregnancy Safety Scanner");
    
    // Add store links
    textToShare.writeln("\n🍎 iOS: ${AppConstants.appStoreUrl}");
    textToShare.writeln("🤖 Android: ${AppConstants.playStoreUrl}");
    
    // Add deep link to view this specific scan (if id exists)
    if (scanData.id != null && scanData.id!.isNotEmpty) {
      final deepLink = '${AppConstants.appDeepLinkBase}/scan?scanId=${scanData.id}';
      textToShare.writeln("\n🔗 View this scan: $deepLink");
    }
    
    textToShare.writeln("\n${l10n.shareDisclaimer}");
    
    // Download and share the product image
    final XFile? imageFileToShare = await _downloadAndPrepareImageForSharing(scanData);
    
    try {
      if (imageFileToShare != null) {
        print("[ScanResultsScreen] Sharing with image: ${imageFileToShare.path}");
        await Share.shareXFiles(
          [imageFileToShare], 
          text: textToShare.toString(), 
          subject: l10n.scanResultSubject(scanData.productName)
        );
        
        // Clean up temporary file if it was downloaded from URL
        if (scanData.imageUrl != null && scanData.imageUrl!.startsWith('http')) {
          try { 
            await File(imageFileToShare.path).delete(); 
            print("[ScanResultsScreen] Deleted temp share file: ${imageFileToShare.path}"); 
          } catch (e) { 
            print("[ScanResultsScreen] Error deleting temp share file: $e"); 
          }
        }
      } else {
        // Fallback to text-only share if image not available
        print("[ScanResultsScreen] No image available, sharing text only");
        await Share.share(textToShare.toString(), subject: l10n.scanResultSubject(scanData.productName));
      }
    } catch (e) {
      print("[ScanResultsScreen] Share error: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSharingContent), 
            backgroundColor: AppTheme.avoidRed
          )
        );
      }
    } finally {
      if (mounted) setState(() { _isProcessingAction = false; });
    }
  }

  /// Downloads the product image and prepares it for sharing
  Future<XFile?> _downloadAndPrepareImageForSharing(ScanData scanData) async {
    try {
      // First, try to use the local scanned image if available
      if (scanData.scannedImagePath != null && scanData.scannedImagePath!.isNotEmpty) {
        final file = File(scanData.scannedImagePath!);
        if (file.existsSync()) {
          print("[ScanResultsScreen] Using local scanned image: ${scanData.scannedImagePath}");
          return XFile(scanData.scannedImagePath!);
        }
      }

      // If no local image, try to download from imageUrl
      if (scanData.imageUrl != null && scanData.imageUrl!.isNotEmpty) {
        print("[ScanResultsScreen] Downloading image from URL: ${scanData.imageUrl}");
        
        final response = await http.get(Uri.parse(scanData.imageUrl!));
        
        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final tempFile = File('${tempDir.path}/share_scan_$timestamp.jpg');
          
          await tempFile.writeAsBytes(bytes);
          print("[ScanResultsScreen] Downloaded image saved to: ${tempFile.path}");
          
          return XFile(tempFile.path);
        } else {
          print("[ScanResultsScreen] Failed to download image, status: ${response.statusCode}");
        }
      }

      print("[ScanResultsScreen] No image available for sharing");
      return null;
    } catch (e) {
      print("[ScanResultsScreen] Error preparing image for sharing: $e");
      return null;
    }
  }

  Widget _buildResultImage(ScanData scanData) {
    if (scanData.imageUrl != null && scanData.imageUrl!.isNotEmpty) {
      return Image.network(
        scanData.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) =>
           progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
      );
    }
    if (scanData.scannedImagePath != null && scanData.scannedImagePath!.isNotEmpty) {
       final file = File(scanData.scannedImagePath!);
       if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.contain, errorBuilder: (c,e,s) => _buildImageErrorPlaceholder());
       } else {
          print("[ScanResultsScreen _buildResultImage] Scanned image path does not exist: ${scanData.scannedImagePath}");
          return _buildImageErrorPlaceholder(); 
       }
    }
    return _buildImageErrorPlaceholder();
  }

  Widget _buildImageErrorPlaceholder() {
    return Center(child: Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary.withOpacity(0.7), size: 60));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final userProfileState = ref.watch(userProfileNotifierProvider);
    // --- THIS IS THE FIX ---
    final bool isPremiumUser = userProfileState.userProfile?.isPremium ?? false;
    final String detailedAnalysisFeatureName = l10n.detailedAnalysisFeatureName;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: AppTheme.lightGrey, elevation: 0, title: Text(l10n.scanResultsTitle),
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor), onPressed: () => context.pop()),
            actions: [IconButton(icon: const Icon(Icons.close, color: AppTheme.primaryColor), onPressed: () => context.go(AppRouter.homePath))],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: AppTheme.lightGrey, elevation: 0, title: Text(l10n.scanResultsTitle),
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor), onPressed: () => context.pop()),
            actions: [IconButton(icon: const Icon(Icons.close, color: AppTheme.primaryColor), onPressed: () => context.go(AppRouter.homePath))],
        ),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center, style: textTheme.titleMedium),
        )),
      );
    }

    // Check if _displayableScanData is null (already somewhat covered by initState logic setting _errorMessage)
    if (_displayableScanData == null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: AppTheme.lightGrey, elevation: 0, title: Text(l10n.scanResultsTitle),
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor), onPressed: () => context.pop()),
            actions: [IconButton(icon: const Icon(Icons.close, color: AppTheme.primaryColor), onPressed: () => context.go(AppRouter.homePath))],
        ),
        body: Center(child: Text(l10n.scanNotFound, style: textTheme.titleMedium))
      );
    }

    // ==== MODIFICATION START ====
    // Explicitly check if _displayableScanData is actually a ScanData object.
    // This addresses the scenario where it might be non-null but of an incorrect type (e.g., String),
    // which could lead to a cast error.
    if (_displayableScanData is! ScanData) {
      print("[ScanResultsScreen build] CRITICAL TYPE ERROR: _displayableScanData was expected to be ScanData but is ${_displayableScanData.runtimeType}. Value: '$_displayableScanData'");
      // Return a generic error UI. It's crucial not to try and use _displayableScanData as ScanData here.
      return Scaffold(
        appBar: AppBar(
            backgroundColor: AppTheme.lightGrey, elevation: 0, title: Text(l10n.scanResultsTitle),
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor), onPressed: () => context.pop()),
            actions: [IconButton(icon: const Icon(Icons.close, color: AppTheme.primaryColor), onPressed: () => context.go(AppRouter.homePath))],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.genericErrorLoadingScan ?? "An unexpected error occurred while trying to display scan results. Data type mismatch.",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium
            ),
          ),
        ),
      );
    }
    // ==== MODIFICATION END ====

    // If we've passed the above checks, _displayableScanData is non-null and is a ScanData instance.
    // So, this cast is now safer.
    final ScanData scanData = _displayableScanData as ScanData; // Using 'as ScanData' because it's confirmed by the check above.

    print("[ScanResultsScreen build] Displaying results for: ${scanData.productName}, RiskLevel: ${scanData.riskLevel}, Bookmarked: $_isBookmarked, rawResponse length: ${scanData.rawResponse?.length ?? 'null'}, isFromManualSearch: ${scanData.isFromManualSearch}");

    final riskStyle = _getRiskLevelStyle(scanData.riskLevel, l10n);
    final Color riskBannerColor = riskStyle['bannerColor'];
    final Color riskTextColor = riskStyle['color'];
    final IconData riskIconForBanner = riskStyle['icon'];
    final String riskBannerMessage = _getRiskBannerMessage(scanData.riskLevel, l10n);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.lightGrey,
        elevation: 0,
        title: Text(l10n.scanResultsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: _isProcessingAction ? null : () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.primaryColor),
            onPressed: _isProcessingAction ? null : () => context.go(AppRouter.homePath),
          ),
        ],
      ),
      // --- FIX START: The body is now a SingleChildScrollView with a Column inside ---
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AbsorbPointer(
            absorbing: _isProcessingAction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(color: riskBannerColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(riskIconForBanner, color: riskTextColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(riskBannerMessage, style: textTheme.bodyLarge?.copyWith(color: riskTextColor, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    height: 220, width: double.infinity,
                    color: AppTheme.dividerColor.withOpacity(0.3),
                    child: _buildResultImage(scanData),
                  ),
                ),
                const SizedBox(height: 20),
                Text(scanData.productName, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(scanData.explanation.isNotEmpty ? scanData.explanation : l10n.notAvailable, style: textTheme.bodyLarge?.copyWith(height: 1.5, color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                if (scanData.safetyTips != null && scanData.safetyTips!.isNotEmpty) ...[
                  _buildSectionCard(
                    context: context, iconPath: 'assets/icons/icon_safety_tips.png', iconColor: AppTheme.primaryBlue,
                    title: l10n.safetyTipsLabel,
                    children: scanData.safetyTips!.map((tip) => _buildTipItem(context, tip)).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                ElevatedButton.icon(
                  style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) return AppTheme.textPrimary.withOpacity(0.5);
                        return _isBookmarked ? AppTheme.safeGreen : AppTheme.primaryBlue;
                      }),
                    foregroundColor: MaterialStateProperty.all(AppTheme.whiteColor),
                  ),
                  onPressed: _isProcessingAction ? null : _toggleBookmark,
                  icon: _isProcessingAction
                      ? Container(width: 20, height: 20, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined, size: 20),
                  label: Text(_isBookmarked ? l10n.removeBookmarkButtonLabel : l10n.addBookmarkButtonLabel),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isProcessingAction ? null : _shareWithDoctor,
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: Text(l10n.shareWithDoctorButton),
                ),
                const SizedBox(height: 12),
                PremiumFeatureWrapper(
                  isPremiumUser: isPremiumUser,
                  onTapWhenFree: () {
                    _showPaywall(context, detailedAnalysisFeatureName);
                  },
                  child: TextButton.icon(
                    onPressed: _isProcessingAction
                               ? null
                               : () {
                                  if (isPremiumUser) {
                                    if (_displayableScanData != null && _displayableScanData is ScanData) { // Added 'is ScanData' for paranoia, though covered above
                                      final ScanData currentScanDataForNav = _displayableScanData as ScanData;
                                      print("[ScanResultsScreen] Navigating to DetailedAnalysisScreen with ScanData ID: ${currentScanDataForNav.id}, isFromManualSearch: ${currentScanDataForNav.isFromManualSearch}");
                                      context.push(AppRouter.detailedAnalysisPath, extra: currentScanDataForNav);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.genericErrorProcessingRequest))
                                      );
                                    }
                                  } else {
                                    _showPaywall(context, detailedAnalysisFeatureName);
                                  }
                                },
                    icon: Icon(
                      isPremiumUser ? Icons.article_outlined : Icons.lock_outline,
                      size: 20,
                      color: isPremiumUser ? Theme.of(context).primaryColor : AppTheme.textSecondary
                    ),
                    label: Text(
                      isPremiumUser ? l10n.scanResultReadMoreButton : l10n.viewDetailedAnalysisPremiumButton,
                      style: TextStyle(color: isPremiumUser ? Theme.of(context).primaryColor : AppTheme.textSecondary)
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (scanData.pregnancyTip.isNotEmpty)
                  _buildSectionCard(
                    context: context, iconPath: 'assets/icons/icon_info_tip.png', iconColor: AppTheme.primaryPurple,
                    title: l10n.pregnancyTipLabel,
                    children: [_buildTipItem(context, scanData.pregnancyTip, isSingleTip: true)],
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      // --- FIX END ---
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String iconPath,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(iconPath, width: 24, height: 24, color: iconColor,
                  errorBuilder: (_,__,___) => Icon(Icons.info_outline, size: 24, color: iconColor)
                ),
                const SizedBox(width: 12),
                Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String tipText, {bool isSingleTip = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSingleTip ? 0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(!isSingleTip) ...[
            Icon(Icons.check_circle_outline, size: 20, color: AppTheme.safeGreen),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              tipText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}