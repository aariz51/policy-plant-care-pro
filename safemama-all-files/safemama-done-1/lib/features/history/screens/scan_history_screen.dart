// lib/features/history/screens/scan_history_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/models/scan_data.dart';
import 'package:safemama/core/services/scan_history_service.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';

// The old filter enum is no longer needed.
// enum HistoryFilter { all, safe, warning, avoid, saved }

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  _ScanHistoryScreenState createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScanHistoryService _scanHistoryService = ScanHistoryService();

  // This list holds the results from the last backend fetch. It's the "master list" for the current view.
  List<ScanData> _scanHistoryItems = [];
  // This list holds the results after applying the client-side text search. This is what's displayed.
  List<ScanData> _filteredResults = [];
  bool _isLoadingHistory = true; // Start in loading state
  String? _historyError;

  // These two variables are now the single source of truth for filtering.
  RiskLevel? _appliedRiskLevelFilter;
  bool _appliedShowOnlyBookmarkedFilter = false;

  Timer? _searchDebounce;
  
  // This helper is unchanged.
  String _riskLevelToString(RiskLevel level, AppLocalizations S) {
    switch (level) {
      case RiskLevel.safe: return S.tagSafe;
      case RiskLevel.caution: return S.tagCaution;
      case RiskLevel.avoid: return S.tagAvoid;
      case RiskLevel.unknown: return S.tagUnknown;
    }
  }

  // =========================================================================
  // ENHANCED PREMIUM FILTER MODAL
  // =========================================================================
  void _showEnhancedFilterModal() {
    final S = AppLocalizations.of(context)!;
    final userProfile = ref.read(userProfileNotifierProvider).userProfile;
    final bool isPremium = userProfile?.membershipTier == 'premium';

    // Guard for non-premium users
    if (!isPremium) {
      showDialog(
        context: context,
        builder: (ctx) => CustomPaywallDialog(
          title: S.premiumFeatureDialogTitle(S.advancedFiltersPremiumFeatureTitle),
          message: S.premiumFeatureDialogMessage(S.advancedFiltersPremiumFeatureTitle),
          icon: Icons.filter_list,
          iconColor: AppTheme.primaryBlue,
        ),
      );
      return;
    }

    // Use a temporary state for the modal so changes are only applied when the user confirms.
    RiskLevel? tempSelectedRisk = _appliedRiskLevelFilter;
    bool tempShowBookmarked = _appliedShowOnlyBookmarkedFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // Set a solid background
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            
            // Calculate counts based on the master list fetched from the backend.
            int countForRisk(RiskLevel level) => _scanHistoryItems.where((i) => i.riskLevel == level).length;
            int bookmarkedCount = _scanHistoryItems.where((i) => i.isBookmarked).length;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text(S.filterScanHistoryTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  Text(S.filterByRiskLevelLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildRiskFilterCard(S.tagSafe, Icons.check_circle_outline, AppTheme.safeGreen, countForRisk(RiskLevel.safe), RiskLevel.safe, tempSelectedRisk, (val) => setStateModal(() => tempSelectedRisk = val)),
                      _buildRiskFilterCard(S.tagCaution, Icons.warning_amber_rounded, AppTheme.warningOrange, countForRisk(RiskLevel.caution), RiskLevel.caution, tempSelectedRisk, (val) => setStateModal(() => tempSelectedRisk = val)),
                      _buildRiskFilterCard(S.tagAvoid, Icons.dangerous_outlined, AppTheme.avoidRed, countForRisk(RiskLevel.avoid), RiskLevel.avoid, tempSelectedRisk, (val) => setStateModal(() => tempSelectedRisk = val)),
                      _buildRiskFilterCard(S.tagUnknown, Icons.help_outline, AppTheme.textSecondary, countForRisk(RiskLevel.unknown), RiskLevel.unknown, tempSelectedRisk, (val) => setStateModal(() => tempSelectedRisk = val)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _buildBookmarkFilterTile(bookmarkedCount, tempShowBookmarked, (val) => setStateModal(() => tempShowBookmarked = val)),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          child: Text(S.buttonClearFilters),
                          onPressed: () => setStateModal(() {
                              tempSelectedRisk = null;
                              tempShowBookmarked = false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: Text(S.buttonApplyFilters),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            // Apply the changes to the screen's state and re-fetch
                            setState(() { 
                              _appliedRiskLevelFilter = tempSelectedRisk;
                              _appliedShowOnlyBookmarkedFilter = tempShowBookmarked;
                            });
                            Navigator.pop(modalContext);
                            _fetchHistoryWithFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- NEW: Helper widget for the interactive risk filter cards ---
  Widget _buildRiskFilterCard(String label, IconData icon, Color color, int count, RiskLevel value, RiskLevel? groupValue, ValueChanged<RiskLevel?> onSelected) {
    final bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onSelected(isSelected ? null : value), // Unselect if tapped again
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.scaffoldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Spacer(),
            Text("$count items", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
  
  // --- NEW: Helper widget for the redesigned bookmark filter ---
  Widget _buildBookmarkFilterTile(int count, bool isSelected, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text("Show Bookmarked Only", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text("$count items saved"),
        value: isSelected,
        onChanged: onChanged,
        secondary: Icon(Icons.bookmark_rounded, color: isSelected ? AppTheme.primaryBlue : AppTheme.iconColor),
        activeColor: AppTheme.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _fetchHistoryWithFilters({bool isRefresh = false}) async {
    if (!mounted) return;
    final userProvider = ref.read(userProfileNotifierProvider);
    final String? userId = userProvider.userId;
    final userProfile = userProvider.userProfile;
    final S = AppLocalizations.of(context)!;
    
    if (userId == null || userProfile == null) {
      if (mounted) setState(() { _isLoadingHistory = false; _historyError = S.errorUserNotAuthenticated; });
      return;
    }

    if (mounted) setState(() { _isLoadingHistory = true; if (isRefresh) _historyError = null; });

    try {
      final fetchedItems = await _scanHistoryService.fetchScanHistory(
        userId: userId,
        userMembershipTier: userProfile.membershipTier ?? 'free',
        filterByRiskLevel: _appliedRiskLevelFilter,
        filterByBookmarked: _appliedShowOnlyBookmarkedFilter ? true : null,
      );
      if (mounted) {
        setState(() {
          _scanHistoryItems = fetchedItems;
          _historyError = null;
        });
        _applyClientSideTextSearch(); 
      }
    } catch (e) {
      if (mounted) setState(() { _historyError = S.historyErrorLoading(e.toString()); });
    } finally {
      if (mounted) setState(() { _isLoadingHistory = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChangedDebounced);
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         _fetchHistoryWithFilters();
       }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChangedDebounced);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChangedDebounced() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _applyClientSideTextSearch();
      }
    });
  }
  
  // This function is now simplified to only handle text search
  void _applyClientSideTextSearch() {
    final searchQuery = _searchController.text.trim().toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _filteredResults = List.from(_scanHistoryItems);
      } else {
        _filteredResults = _scanHistoryItems.where((item) {
          return item.productName.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
  }
  
  Future<void> _refreshHistory() async {
    await _fetchHistoryWithFilters(isRefresh: true);
  }

  // This helper is unchanged.
  String _getMonthAbbreviation(int month, AppLocalizations l10n) {
    const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month < 1 || month > 12) return '???';
    return monthsEn[month - 1];
  }


  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(S.scanHistoryScreenTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: S.filterHistoryTooltip,
            onPressed: _showEnhancedFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: S.historySearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          // THE ROW OF FILTER CHIPS HAS BEEN REMOVED
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(S),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(AppLocalizations S) {
    final textTheme = Theme.of(context).textTheme;

    if (_historyError != null && _filteredResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppTheme.avoidRed, size: 48),
              const SizedBox(height: 16),
              Text(_historyError!, textAlign: TextAlign.center, style: textTheme.titleMedium?.copyWith(color: AppTheme.avoidRed)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _fetchHistoryWithFilters(isRefresh: true),
                icon: const Icon(Icons.refresh),
                label: Text(S.retryButtonLabel),
              )
            ],
          ),
        ),
      );
    }
    
    // Check if the master list is empty (i.e., user has no history at all)
    if (_scanHistoryItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_outlined, size: 60, color: AppTheme.textSecondary.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text(S.historyNoScansYet, style: textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(S.historyNoScansYetSubtitle, textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary.withOpacity(0.8))),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRouter.preScanGuidePath),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(S.goToScanButtonLabel),
              ),
            ],
          ),
        ),
      );
    }

    // Check if the filtered list is empty, but the master list is not
    if (_filteredResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_searchController.text.isNotEmpty ? Icons.search_off_rounded : Icons.filter_list_off_rounded, size: 60, color: AppTheme.textSecondary.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty ? S.historyNoFilterResults : S.historyNoResultsForAppliedFilters,
                style: textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary)
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty ? S.historyNoFilterResultsSubtitle(_searchController.text) : S.tryDifferentFilterOrClear, 
                textAlign: TextAlign.center, 
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary.withOpacity(0.8))
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 80.0),
        itemCount: _filteredResults.length,
        itemBuilder: (context, index) {
          final item = _filteredResults[index];
          return _buildHistoryListItem(context, item, S);
        },
      ),
    );
  }

  // THIS WIDGET IS UNCHANGED
  Widget _buildHistoryListItem(BuildContext context, ScanData item, AppLocalizations S) {
    Color tagBackgroundColor;
    String tagText;

    switch (item.riskLevel) {
      case RiskLevel.safe:
        tagText = S.tagSafe;
        tagBackgroundColor = AppTheme.safeGreen;
        break;
      case RiskLevel.caution:
        tagText = S.tagWarning;
        tagBackgroundColor = AppTheme.warningOrange;
        break;
      case RiskLevel.avoid:
        tagText = S.tagAvoid;
        tagBackgroundColor = AppTheme.avoidRed;
        break;
      default:
        tagText = S.tagUnknown;
        tagBackgroundColor = AppTheme.textSecondary;
    }

    final formattedDate = '${_getMonthAbbreviation(item.createdAt.month, S)} ${item.createdAt.day}, ${item.createdAt.year}';
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push(AppRouter.scanResultsPath, extra: item.id).then((value) {
            if (value == true || value is ScanData) {
               _refreshHistory();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,))),
                        errorBuilder: (context, error, stackTrace) {
                          if (item.scannedImagePath != null && item.scannedImagePath!.isNotEmpty && !item.scannedImagePath!.startsWith('http')) {
                            final localFile = File(item.scannedImagePath!);
                            try {
                                if (localFile.existsSync()){
                                return Image.file(localFile, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary.withOpacity(0.7), size: 30));
                                }
                            } catch (e) { /* File system error */ }
                          }
                          return Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary.withOpacity(0.7), size: 30);
                        },
                      )
                    : (item.scannedImagePath != null && item.scannedImagePath!.isNotEmpty && !item.scannedImagePath!.startsWith('http'))
                       ? Builder(
                           builder: (context) {
                             final localFile = File(item.scannedImagePath!);
                             try {
                               if (localFile.existsSync()) {
                                 return Image.file(localFile, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary.withOpacity(0.7), size: 30));
                               }
                             } catch (e) {
                               print("Error accessing local file for image: ${item.scannedImagePath}, $e");
                             }
                             return Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary.withOpacity(0.7), size: 30);
                           }
                         )
                       : Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary.withOpacity(0.7), size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: tagBackgroundColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(tagText, style: textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis,),
                          ),
                        ),
                        if (item.isBookmarked)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, top: 2.0),
                            child: Icon(Icons.bookmark, color: AppTheme.primaryBlue, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.productName,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textSecondary.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}