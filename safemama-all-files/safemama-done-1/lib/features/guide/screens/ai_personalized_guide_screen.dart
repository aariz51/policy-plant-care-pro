// lib/features/guide/screens/ai_personalized_guide_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:safemama/core/models/user_profile.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/ui/app_markdown_styles.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/ui/markdown_highlight_syntax.dart';
import 'package:safemama/features/guide/providers/ai_guide_providers.dart';

class AiPersonalizedGuideScreen extends ConsumerStatefulWidget {
  const AiPersonalizedGuideScreen({super.key});

  @override
  ConsumerState<AiPersonalizedGuideScreen> createState() =>
      _AiPersonalizedGuideScreenState();
}

class _AiPersonalizedGuideScreenState
    extends ConsumerState<AiPersonalizedGuideScreen> {
  final TextEditingController _topicController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _streamSubscription;

  bool _isLoading = false;
  String _currentTopic = '';
  final StringBuffer _guideContentBuffer = StringBuffer();
  
  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _isNearBottom = position.pixels >= (position.maxScrollExtent - 50.0);
  }

  void _smartScrollToBottom() {
    if (_isNearBottom && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _fetchGuide() async {
    final topic = _topicController.text.trim();
    final userProfile = ref.read(userProfileNotifierProvider).userProfile;
    final languageCode = AppLocalizations.of(context)!.localeName;

    if (topic.isEmpty || userProfile == null || _isLoading) return;

    FocusScope.of(context).unfocus();
    _streamSubscription?.cancel();
    _guideContentBuffer.clear();

    setState(() {
      _isLoading = true;
      _currentTopic = topic;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      _streamSubscription = apiService.generateGuideStream(
        topic: topic,
        languageCode: languageCode,
        userProfile: userProfile,
      ).listen(
        (chunk) {
          // <<< CHANGED: Directly update state with the new chunk
          if (mounted) {
            setState(() {
              _guideContentBuffer.write(chunk);
            });
            _smartScrollToBottom();
          }
        },
        onDone: () {
          ref.read(aiGuideProvider.notifier).guideGenerationComplete();
          if(mounted) {
            // <<< CHANGED: Final state update to switch to MarkdownBody
            setState(() {
              _isLoading = false;
            });
          }
          _streamSubscription = null;
        },
        onError: (e) {
          if(mounted) {
            setState(() {
              _isLoading = false;
              _currentTopic = '';
            });
          }
          _handleError(e, userProfile);
          _streamSubscription = null;
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentTopic = '';
      });
      _handleError(e, userProfile);
    }
  }

  // _handleError method is unchanged
  void _handleError(Object e, UserProfile userProfile) {
    if (!mounted) return;
    final errorMessage = e.toString().replaceFirst('Exception: ', '');
    if (errorMessage.startsWith('LIMIT_REACHED')) {
      final message = errorMessage.replaceFirst('LIMIT_REACHED: ', '');
      showDialog(
        context: context,
        builder: (_) => CustomPaywallDialog(
          title: "Limit Reached",
          message: message,
          icon: Icons.auto_awesome_outlined,
          iconColor: AppTheme.primaryPurple,
          type: PaywallType.cooldown,
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTopic.isNotEmpty ? _currentTopic : S.aiPersonalizedGuideScreenTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Section remains unchanged
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      labelText: S.aiGuideTopicInputLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: _isLoading ? null : (_) => _fetchGuide(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.search),
                  onPressed: _isLoading ? null : _fetchGuide,
                  style: IconButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // <<< CHANGED: Content Section is now managed by a helper method
            Expanded(
              child: _buildContentArea(S),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main content area based on the current state.
  Widget _buildContentArea(AppLocalizations S) {
    // Case 1: Loading has started but no content has arrived yet.
    if (_isLoading && _guideContentBuffer.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Case 2: Content is available (either streaming or complete).
    if (_guideContentBuffer.isNotEmpty) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: _buildGuideContent(context),
      );
    }

    // Case 3: Initial state before any generation.
    return Center(
      child: Text(
        S.aiGuideInitialPrompt,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Returns the appropriate widget for the guide content:
  /// A lightweight [SelectableText] while streaming, or a
  /// full [MarkdownBody] when finished.
  Widget _buildGuideContent(BuildContext context) {
    // While streaming, use a lightweight and fast RichText widget.
    if (_isLoading) {
      return SelectableText.rich(
        TextSpan(
          // Use the default text style from the theme for consistency.
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            TextSpan(text: _guideContentBuffer.toString()),
            const TextSpan(text: '▍', style: TextStyle(color: Colors.grey)), // Typing cursor
          ],
        ),
        // Ensures the padding aligns with MarkdownBody's default for a smooth transition.
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }
    // After streaming is done, render the final, expensive MarkdownBody once.
    else {
      return MarkdownBody(
        data: _guideContentBuffer.toString(),
        selectable: true,
        styleSheet: AppMarkdownStyles.getStyleSheet(context),
        inlineSyntaxes: [HighlightSyntax()],
        builders: {'mark': HighlightBuilder()},
      );
    }
  }
}