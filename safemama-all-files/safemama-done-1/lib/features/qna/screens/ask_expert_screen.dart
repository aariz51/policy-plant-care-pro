// lib/features/qna/screens/ask_expert_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/models/user_profile.dart';
import 'package:safemama/core/constants/app_constants.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/ui/app_markdown_styles.dart';
import 'package:safemama/core/ui/markdown_highlight_syntax.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/features/qna/providers/ask_expert_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <<< ADDED: Supabase import
import 'package:safemama/core/models/chat_message.dart';
import 'package:safemama/navigation/app_router.dart';


// Add this provider if missing
final askExpertHistoryProvider = StateNotifierProvider<AskExpertHistoryNotifier, AskExpertHistoryState>((ref) {
  return AskExpertHistoryNotifier();
});

// Add this class if missing
class AskExpertHistoryNotifier extends StateNotifier<AskExpertHistoryState> {
  AskExpertHistoryNotifier() : super(AskExpertHistoryState(messages: []));
  
  void addConversationToHistory(List<ChatMessage> messages) {
    state = state.copyWith(messages: [...state.messages, ...messages]);
  }
}

class AskExpertHistoryState {
  final List<ChatMessage> messages;
  
  const AskExpertHistoryState({required this.messages});
  
  AskExpertHistoryState copyWith({List<ChatMessage>? messages}) {
    return AskExpertHistoryState(messages: messages ?? this.messages);
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;
  
  const ChatMessage({required this.text, required this.isUserMessage});
}

// <<< MODIFIED: UIMessage now holds the original user question for context
class UIMessage {
  String text;
  final bool isUserMessage;
  bool isStreaming;
  final String? userQuestion; // To store the user's question for reporting

  UIMessage({
    required this.text,
    required this.isUserMessage,
    this.isStreaming = false,
    this.userQuestion,
  });
}

class AskExpertScreen extends ConsumerStatefulWidget {
  const AskExpertScreen({super.key});

  @override
  ConsumerState<AskExpertScreen> createState() => _AskExpertScreenState();
}

class _AskExpertScreenState extends ConsumerState<AskExpertScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _streamSubscription;

  final List<UIMessage> _messages = [];
  bool _isLoading = false;

  final StringBuffer _finalResponseBuffer = StringBuffer();

  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _questionController.dispose();
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

  // --- REPLACED THE ENTIRE _reportMessage method with this corrected version ---
  Future<void> _reportMessage(UIMessage message) async {
    final S = AppLocalizations.of(context)!;
    final userProfile = ref.read(userProfileNotifierProvider).userProfile;
    if (userProfile == null) return;

    final reportController = TextEditingController();

    // Show the dialog to get the reason for the report
    final String? reportReason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Report Content"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Please provide a brief reason for reporting this AI-generated response (e.g., 'incorrect', 'offensive', 'not helpful')."),
            const SizedBox(height: 16),
            TextField(
              controller: reportController,
              decoration: const InputDecoration(hintText: "Reason for reporting..."),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            // This now returns null, indicating cancellation.
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(S.cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () {
              // This now returns the text, indicating submission.
              Navigator.of(dialogContext).pop(reportController.text.trim());
            },
            child: const Text("Submit Report"),
          ),
        ],
      ),
    );

    // --- THIS IS THE FIX ---
    // We now check if reportReason is not null. If it's null, it means the user
    // pressed "Cancel" or tapped outside the dialog, so we do nothing.
    if (reportReason != null) {
      // Create a local reference to the messenger before the async gap.
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text("Submitting report...")));
      
      try {
        await Supabase.instance.client.from('reported_content').insert({
          'user_id': userProfile.id,
          'reported_content': message.text,
          'user_question': message.userQuestion,
          'reason': reportReason,
        });
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Thank you for your feedback. The content has been reported for review."),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
      } catch (e) {
        print("Error submitting report: $e");
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Could not submit report. Please try again."),
            backgroundColor: AppTheme.avoidRed,
          ),
        );
      }
    }
  }


  Future<void> _submitQuestion() async {
    final questionText = _questionController.text.trim();
    final userProfile = ref.read(userProfileNotifierProvider).userProfile;

    if (questionText.isEmpty || userProfile == null || _isLoading) return;

    _questionController.clear();
    FocusScope.of(context).unfocus();

    final userMessage = UIMessage(text: questionText, isUserMessage: true);
    
    // <<< MODIFIED: AI message now includes the user's question for context
    final aiMessage = UIMessage(
        text: '', 
        isUserMessage: false, 
        isStreaming: true,
        userQuestion: questionText, // <-- Important for reporting
    );

    setState(() {
      _isLoading = true;
      _messages.add(userMessage);
      _messages.add(aiMessage); // Add the placeholder
    });

    _smartScrollToBottom();
    _finalResponseBuffer.clear();

    try {
      final apiService = ref.read(apiServiceProvider);
      _streamSubscription = apiService.askExpertStream(
        question: questionText,
        userProfile: userProfile,
      ).listen(
        (chunk) {
          setState(() {
            _messages.last.text += chunk;
          });
          _finalResponseBuffer.write(chunk); 
          _smartScrollToBottom();
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            if (_messages.isNotEmpty) {
               _messages.last.isStreaming = false;
            }
          });
          ref.read(askExpertHistoryProvider.notifier).addConversationToHistory([
                ChatMessage(text: userMessage.text, isUserMessage: true),
                ChatMessage(text: _finalResponseBuffer.toString(), isUserMessage: false),
              ]);
          _streamSubscription = null;
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _messages.removeLast();
            _messages.removeLast();
          });
          _handleError(e, userProfile);
          _streamSubscription = null;
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.removeLast();
        _messages.removeLast();
      });
      _handleError(e, userProfile);
    }
  }

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
          icon: Icons.chat_bubble_outline,
          iconColor: AppTheme.accentColor,
          type: userProfile.membershipTier?.startsWith('premium') == true ? PaywallType.cooldown : PaywallType.upgrade,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final userProfile = ref.watch(userProfileNotifierProvider).userProfile;

    // <<< MODIFIED: History loading logic is now aware of userQuestion context
    final historicalMessages = ref.watch(askExpertHistoryProvider).messages;
    if (_messages.isEmpty && historicalMessages.isNotEmpty) {
       for (int i = 0; i < historicalMessages.length; i++) {
            final msg = historicalMessages[i];
            String? originalQuestion;
            // If this is an AI message (and not the very first message),
            // the preceding message is the user's question.
            if (!msg.isUserMessage && i > 0) {
                final precedingMsg = historicalMessages[i - 1];
                if (precedingMsg.isUserMessage) {
                    originalQuestion = precedingMsg.text;
                }
            }
            _messages.add(UIMessage(
                text: msg.text,
                isUserMessage: msg.isUserMessage,
                isStreaming: false,
                userQuestion: originalQuestion,
            ));
        }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.askAnExpertTitle),
      ),
      body: Column(
        children: [
          if (userProfile != null) _buildUsageCounter(context, userProfile),
          Expanded(
            child: _messages.isEmpty
                ? _buildInitialPrompt(context, S)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      // <<< MODIFIED: Pass the new _reportMessage function to the ChatBubble
                      return ChatBubble(
                        message: message,
                        onReport: _reportMessage,
                      );
                    },
                  ),
          ),
          _BuildInputField(
            controller: _questionController,
            isLoading: _isLoading,
            onSubmit: _submitQuestion,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCounter(BuildContext context, UserProfile userProfile) {
    final bool isFree = !(userProfile.isPremium ?? false);
    
    // Get correct limit based on membership tier
    int limit;
    String period;
    if (isFree) {
      limit = AppConstants.freeAskExpertLimit;
      period = 'month';
    } else {
      // Get tier-specific limit
      final tier = userProfile.membershipTier?.toLowerCase().trim() ?? 'premium_monthly';
      if (tier.contains('weekly')) {
        limit = AppConstants.premiumWeeklyAskExpertLimit;
        period = 'week';
      } else if (tier.contains('yearly') || tier.contains('annual')) {
        limit = AppConstants.premiumYearlyAskExpertLimit;
        period = 'year';
      } else {
        // Default to monthly
        limit = AppConstants.premiumMonthlyAskExpertLimit;
        period = 'month';
      }
    }
    
    int used = userProfile.askExpertCount;
    int remaining = limit - used;
    if (remaining < 0) remaining = 0;

    return Container(
      color: Colors.blueGrey.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Text(
          isFree
              ? "You have $remaining of $limit free questions remaining."
              : "Questions this $period: $used of $limit",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildInitialPrompt(BuildContext context, AppLocalizations S) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              S.askExpertDisclaimer,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// <<< MODIFIED: The chat bubble now accepts an onReport callback
class ChatBubble extends StatelessWidget {
  final UIMessage message;
  final Function(UIMessage) onReport; // Callback for reporting

  const ChatBubble({
    super.key,
    required this.message,
    required this.onReport, // Required callback
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUserMessage = message.isUserMessage;

    Widget content;
    if (!isUserMessage && message.isStreaming) {
      content = RichText(
        text: TextSpan(
          style: theme.textTheme.bodyLarge,
          children: [
            TextSpan(text: message.text),
            const TextSpan(text: '▍', style: TextStyle(color: Colors.grey)), // Typing cursor
          ],
        ),
      );
    }
    else if (isUserMessage) {
      content = Text(
        message.text,
        style: TextStyle(color: theme.colorScheme.onPrimary),
      );
    }
    else {
      content = MarkdownBody(
        data: message.text,
        selectable: true,
        styleSheet: AppMarkdownStyles.getStyleSheet(context),
        inlineSyntaxes: [HighlightSyntax()],
        builders: {'mark': HighlightBuilder()},
      );
    }

    // <<< MODIFIED: Widget is now a Column to hold the bubble and the report button >>>
    return Column(
      crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: isUserMessage ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: content,
          ),
        ),
        // Conditionally add the Report button for completed AI messages
        if (!isUserMessage && !message.isStreaming && message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: TextButton.icon(
              onPressed: () => onReport(message),
              icon: const Icon(Icons.flag_outlined, size: 14, color: AppTheme.textSecondary),
              label: const Text("Report", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }
}

// This widget remains unchanged
class _BuildInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _BuildInputField({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    return Material(
      elevation: 5.0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 8.0,
          top: 8.0,
          bottom: MediaQuery.of(context).padding.bottom + 8.0,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: S.typeYourQuestionHint,
                  border: InputBorder.none,
                  filled: false,
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : (_) => onSubmit(),
                maxLines: 5,
                minLines: 1,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
              onPressed: isLoading ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
