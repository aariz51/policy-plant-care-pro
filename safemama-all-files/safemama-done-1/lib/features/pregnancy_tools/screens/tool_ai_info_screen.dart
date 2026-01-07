// lib/features/pregnancy_tools/screens/tool_ai_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:safemama/core/constants/app_colors.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart'; // Import the user profile provider

class ToolAIInfoScreen extends ConsumerStatefulWidget {
  final String toolName;
  final String toolEndpoint;
  final IconData toolIcon;
  final Color toolColor;
  final Map<String, dynamic>? additionalContext;

  const ToolAIInfoScreen({
    Key? key,
    required this.toolName,
    required this.toolEndpoint,
    required this.toolIcon,
    required this.toolColor,
    this.additionalContext,
  }) : super(key: key);

  @override
  ConsumerState<ToolAIInfoScreen> createState() => _ToolAIInfoScreenState();
}

class _ToolAIInfoScreenState extends ConsumerState<ToolAIInfoScreen> {
  String _streamedContent = '';
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAIInfo();
  }

  Future<void> _fetchAIInfo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final userProfile = ref.read(userProfileProvider).userProfile; // Corrected user profile reading
      final apiService = ApiService();

      if (userProfile == null) {
        throw Exception("User profile not available.");
      }

      final userContext = {
        'trimester': userProfile.selectedTrimester,
        'allergies': userProfile.knownAllergies,
        'dietaryPreference': userProfile.dietaryPreference,
        'toolName': widget.toolName,
        ...?widget.additionalContext,
      };

      // Use streaming API endpoint
      final stream = apiService.askExpertStream(
        question: 'Provide detailed information about ${widget.toolName} during pregnancy',
        userProfile: userProfile,
      );

      await for (final chunk in stream) {
        if (mounted) {
          setState(() {
            _streamedContent += chunk;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('${widget.toolName} - AI Information'),
        backgroundColor: widget.toolColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && !_hasError)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Share functionality
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load AI information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchAIInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.toolColor, widget.toolColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.toolColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.toolIcon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.toolName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI-Powered Information',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isLoading
                ? Column(
                    children: [
                      CircularProgressIndicator(color: widget.toolColor),
                      const SizedBox(height: 16),
                      Text(
                        'Loading AI information...',
                        style: TextStyle(color: AppColors.textMedium),
                      ),
                    ],
                  )
                : MarkdownBody(
                    data: _streamedContent.isNotEmpty
                        ? _streamedContent
                        : 'No information available.',
                    styleSheet: MarkdownStyleSheet(
                      h1: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.toolColor,
                      ),
                      h2: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.toolColor,
                      ),
                      h3: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      p: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.textDark,
                      ),
                      listBullet: TextStyle(color: widget.toolColor),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.toolColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}