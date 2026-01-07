// lib/features/search/screens/manual_search_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/models/scan_data.dart';
import 'package:safemama/core/theme/app_theme.dart';
// NEW, CORRECT IMPORT
import 'package:safemama/core/widgets/paywall_dialog.dart'; 
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http; // --- NEW: Direct http import
import 'package:safemama/core/constants/app_constants.dart'; // For backend URL
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase instance

// --- NEW: Model for the simplified AI search result ---
class AiSearchResult {
  final String riskLevel; // "safe", "caution", "avoid"
  final String explanation;
  final String? tip;

  AiSearchResult({required this.riskLevel, required this.explanation, this.tip});

  factory AiSearchResult.fromJson(Map<String, dynamic> json) {
    return AiSearchResult(
      riskLevel: json['riskLevel'] as String? ?? 'unknown',
      explanation: json['explanation'] as String? ?? 'No explanation available.',
      tip: json['tip'] as String?,
    );
  }
}


class ManualSearchScreen extends ConsumerStatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  _ManualSearchScreenState createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends ConsumerState<ManualSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Timer? _debounce; // <-- DELETED THIS

  List<ScanData> _userHistoryResults = [];
  // --- NEW: State for the simplified AI result ---
  AiSearchResult? _aiSearchResult;

  bool _isLoading = false;
  bool _hasSearched = false;
  String _searchError = '';
  String _currentSearchTerm = '';

  // STEP 1: Comment out these two lines
  // final stt.SpeechToText _speech = stt.SpeechToText();
  // bool _isListening = false;
  
  // --- All other state and initState/dispose/voice methods remain the same ---
  // ... (initState, dispose, _initializeSpeechRecognizer, _toggleListening)

  @override
  void initState() {
    super.initState();
    // _searchController.addListener(_onSearchChangedDebounced); // <-- DELETED THIS LINE
    // STEP 2: Comment out this line
    // _initializeSpeechRecognizer();
  }

  @override
  void dispose() {
    // _searchController.removeListener(_onSearchChangedDebounced); // <-- DELETED THIS LINE
    _searchController.dispose();
    // _debounce?.cancel(); // <-- DELETED THIS
    // _speech.stop();
    super.dispose();
  }
  
  // STEP 3: Comment out these entire methods
  /*
  Future<void> _initializeSpeechRecognizer() async {
    await _speech.initialize(
      onStatus: (status) => print('[SpeechToText] status: $status'),
      onError: (error) => print('[SpeechToText] error: $error'),
    );
  }

  void _toggleListening() async {
    if (!_speech.isAvailable) {
      await _initializeSpeechRecognizer();
    }
    
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (_speech.isAvailable) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _searchController.text = result.recognizedWords;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              });
              if (result.finalResult) {
                setState(() => _isListening = false);
                _performSearch(result.recognizedWords.trim());
              }
            }
          },
          localeId: ref.read(localeProvider).currentLocale.toString(),
        );
      } else {
        final S = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.voiceSearchNotAvailable)));
      }
    }
  }
  */

  /*
  // DELETED THIS ENTIRE METHOD
  void _onSearchChangedDebounced() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      final query = _searchController.text.trim();
      if (query.isEmpty || query.length >= 2) {
        _performSearch(query);
      } else if (query.length < 2 && (_userHistoryResults.isNotEmpty || _aiSearchResult != null)) {
        if (mounted) {
          setState(() {
            _userHistoryResults = [];
            _aiSearchResult = null;
            _hasSearched = false;
            _currentSearchTerm = query;
          });
        }
      }
    });
  }
  */

  Future<void> _performSearch(String searchTerm) async {
    if (!mounted) return;

    final S = AppLocalizations.of(context)!;
    final userProfile = ref.read(userProfileNotifierProvider).userProfile;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchError = '';
      _currentSearchTerm = searchTerm;
      _userHistoryResults = [];
      _aiSearchResult = null; // Reset AI result
    });

    if (searchTerm.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    if (userProfile == null || userProfile.id.isEmpty) {
      if (mounted) setState(() { _searchError = S.errorUserNotAuthenticated; _isLoading = false; });
      return;
    }

    final userId = userProfile.id;
    // Use the robust `isPremium` getter from the model
    final bool isPremium = userProfile.isPremium ?? false;

    try {
      // Step 1: Always search local history
      final scanHistoryService = ref.read(scanHistoryServiceProvider);
      final historyResults = await scanHistoryService.searchUserScanHistoryByName(userId, searchTerm, limit: 5);
      if (!mounted) return;
      setState(() { _userHistoryResults = historyResults; });

      // --- MODIFY THE AI SEARCH BLOCK ---
      if (isPremium) {
        print("[ManualSearchScreen] Premium user. Performing simplified AI Search for: $searchTerm");
        
        // Get the auth token
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token == null) {
          throw Exception('User not authenticated for premium search.');
        }

        final response = await http.post(
          Uri.parse('${AppConstants.yourBackendBaseUrl}/api/analyze-term'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token', // <-- SEND THE TOKEN
          },
          body: jsonEncode({'productName': searchTerm})
        );
        
        if (!mounted) return;

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          // After a successful search, also update the local provider count
          ref.read(userProfileNotifierProvider.notifier).incrementManualSearchCount();
          setState(() {
            _aiSearchResult = AiSearchResult.fromJson(jsonResponse);
          });
        } else {
          // --- THIS IS THE NEW PART FOR HANDLING SPECIFIC ERRORS ---
          final errorBody = jsonDecode(response.body);
          final String serverError = errorBody['error'] ?? 'Failed to get AI analysis';
          final bool limitReached = errorBody['limitReached'] as bool? ?? false;

          if (limitReached) {
            // If the backend says the limit was reached, throw a specific exception
            // that we can catch below.
            throw Exception('LIMIT_REACHED: $serverError');
          } else {
            // For other errors, throw a general exception
            throw Exception(serverError);
          }
          // --- END OF NEW PART ---
        }
      }
    } catch (e) {
      print("[ManualSearchScreen] Error during search: $e");
      if (!mounted) return;

      // --- THIS IS THE NEW, SMARTER CATCH BLOCK ---
      final errorMessage = e.toString();

      if (errorMessage.contains('LIMIT_REACHED')) {
        // We caught our specific limit exception!
        // Now, we show the proper paywall dialog.
        final S = AppLocalizations.of(context)!;
        final userProfile = ref.read(userProfileNotifierProvider).userProfile;
        final message = errorMessage.replaceFirst('Exception: LIMIT_REACHED: ', '');

        showDialog(
          context: context,
          builder: (ctx) => CustomPaywallDialog(
            title: "Search Limit Reached",
            message: message,
            icon: Icons.search_off,
            iconColor: AppTheme.primaryBlue,
            type: userProfile?.membershipTier == 'premium_monthly' 
                  ? PaywallType.upgrade // Encourage upgrade to yearly
                  : PaywallType.cooldown,
          ),
        );
        // Clear the generic error message if we showed the dialog
        setState(() { _searchError = ''; });
      } else {
        // For any other error, show the generic message.
        setState(() { _searchError = S.genericSearchError; });
      }
      // --- END OF NEW CATCH BLOCK ---

    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(S.manualSearchScreenTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: S.searchItemsHint,
                prefixIcon: const Icon(Icons.search),
                // --- THIS IS THE MODIFIED SUFFIX ICON LOGIC ---
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // STEP 5: Comment out this IconButton
                    /*
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _isLoading ? null : _toggleListening,
                      tooltip: S.searchByVoiceTooltip,
                    ),
                    */
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                    // ADDED a dedicated search button
                    IconButton(
                      icon: const Icon(Icons.send),
                      tooltip: 'Search',
                      color: Theme.of(context).primaryColor,
                      onPressed: _isLoading 
                        ? null 
                        : () => _performSearch(_searchController.text.trim()),
                    ),
                  ],
                ),
                // --- END OF MODIFICATION ---
              ),
              textInputAction: TextInputAction.search,
              // This now triggers the search when the keyboard's search/enter button is pressed
              onSubmitted: (value) => _performSearch(value.trim()),
            ),
          ),
          Expanded(
            child: _buildResultsArea(S),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsArea(AppLocalizations S) {
    final userProfile = ref.watch(userProfileNotifierProvider).userProfile;
    final bool isPremium = userProfile?.isPremium ?? false;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_searchError.isNotEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_searchError, style: TextStyle(color: AppTheme.avoidRed), textAlign: TextAlign.center)));
    if (!_hasSearched || _currentSearchTerm.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(S.searchPromptStartTyping, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary), textAlign: TextAlign.center)));

    final bool hasHistoryResults = _userHistoryResults.isNotEmpty;
    final bool hasAiResult = _aiSearchResult != null;

    if (!hasHistoryResults && !hasAiResult) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(S.searchNoResultsMessage(_currentSearchTerm), textAlign: TextAlign.center)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
      children: [
        if (isPremium && hasAiResult) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
            child: Text(S.searchResultsSectionAI, style: Theme.of(context).textTheme.titleMedium),
          ),
          _buildQuickAiResultCard(_aiSearchResult!, S),
        ],
        
        if (hasHistoryResults) ...[
          Padding(
            padding: EdgeInsets.only(top: hasAiResult ? 24.0 : 8.0, bottom: 12.0),
            child: Text(S.searchResultsSectionHistory, style: Theme.of(context).textTheme.titleMedium),
          ),
          ..._userHistoryResults.map((item) => _buildUserHistorySearchResultItem(context, item, S)),
        ],

        if (!isPremium && _currentSearchTerm.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Card(
              elevation: 1,
              color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.7),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(S.freeSearchAiPrompt, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      child: Text(S.buttonUpgrade),
                      onPressed: () => GoRouter.of(context).push(AppRouter.upgradePath),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // --- NEW: Widget to display the simplified AI result ---
  Widget _buildQuickAiResultCard(AiSearchResult result, AppLocalizations S) {
    Color tagColor;
    String tagText;
    IconData tagIcon;

    switch (result.riskLevel) {
      case 'safe': tagColor = AppTheme.safeGreen; tagText = S.tagSafe.toUpperCase(); tagIcon = Icons.check_circle_outline; break;
      case 'caution': tagColor = AppTheme.warningOrange; tagText = S.tagCaution.toUpperCase(); tagIcon = Icons.warning_amber_rounded; break;
      case 'avoid': tagColor = AppTheme.avoidRed; tagText = S.tagAvoid.toUpperCase(); tagIcon = Icons.dangerous_outlined; break;
      default: tagColor = AppTheme.textSecondary; tagText = S.tagInfo.toUpperCase(); tagIcon = Icons.info_outline; break;
    }
    
    return Card(
      elevation: 2,
      color: tagColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tagColor.withOpacity(0.3))
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tagIcon, color: tagColor, size: 20),
                const SizedBox(width: 8),
                Text(tagText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tagColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.explanation, style: Theme.of(context).textTheme.bodyLarge),
            if (result.tip != null && result.tip!.isNotEmpty) ...[
              const Divider(height: 24, thickness: 0.5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.primaryPurple),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.tip!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  // --- This method remains the same ---
  Widget _buildUserHistorySearchResultItem(BuildContext context, ScanData item, AppLocalizations S) {
    // ... (This method's code is unchanged from the previous version)
     Color tagBackgroundColor;
    String tagText;
    IconData tagIcon;

    switch (item.riskLevel) {
      case RiskLevel.safe: tagText = S.tagSafe; tagBackgroundColor = AppTheme.safeGreen; tagIcon = Icons.check_circle_outline; break;
      case RiskLevel.caution: tagText = S.tagUseWithCaution; tagBackgroundColor = AppTheme.warningOrange; tagIcon = Icons.warning_amber_rounded; break;
      case RiskLevel.avoid: tagText = S.tagNotSafe; tagBackgroundColor = AppTheme.avoidRed; tagIcon = Icons.dangerous_outlined; break;
      default: tagText = S.tagInfo; tagBackgroundColor = AppTheme.primaryBlue; tagIcon = Icons.info_outline; break;
    }
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => GoRouter.of(context).push(AppRouter.scanResultsPath, extra: item),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: AppTheme.dividerColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), clipBehavior: Clip.antiAlias,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty ? Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 30)) : const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [ Icon(tagIcon, size: 14, color: tagBackgroundColor), const SizedBox(width: 4), Flexible(child: Text(tagText, style: textTheme.labelSmall?.copyWith(color: tagBackgroundColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)) ],
                     ),
                     const SizedBox(height: 4),
                     Text(item.productName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                     if (item.brandName != null && item.brandName!.isNotEmpty) ...[const SizedBox(height: 2), Text(item.brandName!, style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary.withOpacity(0.8)), maxLines: 1, overflow: TextOverflow.ellipsis)],
                     if (item.explanation.isNotEmpty) ...[const SizedBox(height: 2), Text(item.explanation, style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)]
                   ],
                 ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppTheme.textSecondary.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}