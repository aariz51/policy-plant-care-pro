// lib/features/pregnancy_tools/screens/streaming_ai_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/ui/app_markdown_styles.dart';
import 'package:safemama/core/ui/markdown_highlight_syntax.dart';
import 'package:safemama/navigation/app_router.dart';
import 'dart:async';

/// A reusable screen that displays AI analysis with streaming support and
/// beautiful markdown rendering, similar to the Ask the Expert feature.
class StreamingAIResultScreen extends ConsumerStatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<String> responseStream;

  const StreamingAIResultScreen({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.responseStream,
  }) : super(key: key);

  @override
  ConsumerState<StreamingAIResultScreen> createState() => _StreamingAIResultScreenState();
}

class _StreamingAIResultScreenState extends ConsumerState<StreamingAIResultScreen> {
  final StringBuffer _responseBuffer = StringBuffer();
  final ScrollController _scrollController = ScrollController();
  bool _isStreaming = true;
  bool _hasError = false;
  String? _errorMessage;
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    // Delay starting the stream slightly to ensure widget is fully mounted
    Future.microtask(() {
      if (mounted) {
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startListening() {
    print('[StreamingAIResult] Starting to listen to stream...');
    _streamSubscription = widget.responseStream.listen(
      (chunk) {
        if (!mounted) return;
        print('[StreamingAIResult] Received chunk of length: ${chunk.length}');
        setState(() {
          _responseBuffer.write(chunk);
        });
        _smartScrollToBottom();
      },
      onDone: () {
        if (!mounted) return;
        print('[StreamingAIResult] Streaming completed. Total length: ${_responseBuffer.length}');
        setState(() {
          _isStreaming = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        print('[StreamingAIResult] Stream error: $error');
        setState(() {
          _isStreaming = false;
          _hasError = true;
          _errorMessage = error.toString().replaceAll('Exception: ', '');
        });
      },
      cancelOnError: true,
    );
  }

  void _smartScrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _hasError ? _buildErrorView() : _buildContentView(),
    );
  }

  Widget _buildErrorView() {
    // Parse error message to determine error type
    final errorStr = _errorMessage ?? '';
    
    // Check for premium required error FIRST (403 or isPremiumRequired in response)
    final isPremiumRequiredError = errorStr.contains('403') || 
                                   errorStr.contains('isPremiumRequired') ||
                                   errorStr.contains('Premium subscription required');
    
    final isRateLimitError = errorStr.contains('429') || 
                             errorStr.contains('rate limit') || 
                             errorStr.contains('Please wait') ||
                             errorStr.contains('cooldown') ||
                             errorStr.contains('too many');
    
    // Extract wait time if present
    final waitTimeMatch = RegExp(r'(\d+)\s*seconds?').firstMatch(errorStr);
    final waitSeconds = waitTimeMatch != null ? int.tryParse(waitTimeMatch.group(1) ?? '') : null;
    
    // Determine the message and styling based on error type
    String title;
    String message;
    IconData icon;
    Color iconColor;
    bool showUpgradeButton = false;
    
    if (isPremiumRequiredError) {
      // Premium required - show beautiful upgrade message
      title = '✨ Premium Feature';
      icon = Icons.workspace_premium;
      iconColor = const Color(0xFFFFD700); // Gold
      message = 'AI Analysis is a premium feature.\n\nUpgrade your plan to unlock personalized AI insights for all pregnancy tools.';
      showUpgradeButton = true;
    } else if (isRateLimitError) {
      title = '⏳ Please Slow Down';
      icon = Icons.timer_outlined;
      iconColor = AppTheme.warningOrange;
      
      if (waitSeconds != null) {
        message = 'You\'re making requests too quickly.\n\nPlease wait $waitSeconds seconds before trying again.';
      } else {
        message = 'You\'re making requests too quickly.\n\nPlease wait a moment before trying again.';
      }
    } else {
      title = 'Unable to Generate Analysis';
      // Clean up any JSON-like content for better display
      if (errorStr.contains('{') && errorStr.contains('}')) {
        message = 'An error occurred while generating the analysis. Please try again later.';
      } else {
        message = errorStr.isNotEmpty 
            ? errorStr.replaceAll(RegExp(r'Failed to get AI analysis\. Status: \d+,? ?Body:'), '').trim()
            : 'An error occurred while generating the analysis.';
      }
      icon = Icons.error_outline;
      iconColor = AppTheme.dangerRed;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isRateLimitError && waitSeconds != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'This helps protect our AI service',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // Show different buttons based on error type
            if (showUpgradeButton) ...[
              // Golden Upgrade Button for premium features
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRouter.upgradePath);
                },
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Upgrade Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700), // Gold
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Go Back'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ] else ...[
              // Standard Go Back button for other errors
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return Column(
      children: [
        // Header with icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.1),
                widget.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: widget.color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isStreaming ? 'Generating analysis...' : 'Analysis complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              if (_isStreaming)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                ),
            ],
          ),
        ),

        // Content area with streaming/markdown
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: _buildResponseContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseContent() {
    final responseText = _responseBuffer.toString();

    if (responseText.isEmpty && _isStreaming) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
            const SizedBox(height: 16),
            Text(
              'Starting analysis...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    // While streaming, show plain text with typing cursor for better performance
    if (_isStreaming) {
      return SelectableText.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 16,
              ),
          children: [
            TextSpan(text: responseText),
            const TextSpan(
              text: '▍',
              style: TextStyle(color: Colors.grey), // Typing cursor
            ),
          ],
        ),
      );
    }

    // After streaming is done, render beautiful markdown
    return MarkdownBody(
      data: responseText,
      selectable: true,
      styleSheet: AppMarkdownStyles.getStyleSheet(context),
      inlineSyntaxes: [HighlightSyntax()],
      builders: {'mark': HighlightBuilder()},
    );
  }
}

