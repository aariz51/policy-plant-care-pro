import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
import 'package:safemama/features/qna/providers/document_analysis_providers.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:safemama/core/ui/app_markdown_styles.dart';
import 'package:safemama/core/ui/markdown_highlight_syntax.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:safemama/core/services/api_service.dart'; // Assuming you have an ApiService

class DocumentAnalysisScreen extends ConsumerStatefulWidget {
  const DocumentAnalysisScreen({super.key});

  @override
  ConsumerState<DocumentAnalysisScreen> createState() => _DocumentAnalysisScreenState();
}

class _DocumentAnalysisScreenState extends ConsumerState<DocumentAnalysisScreen> 
    with SingleTickerProviderStateMixin {
  String selectedDocumentType = 'ultrasound';
  File? selectedDocument;
  late AnimationController _uploadAnimationController;
  late Animation<double> _uploadAnimation;

  // Add state variables for streaming
  StringBuffer _streamBuffer = StringBuffer();
  StreamSubscription<String>? _streamSub;
  bool _isStreaming = false;
  final ScrollController _scrollController = ScrollController();


  final List<Map<String, dynamic>> documentTypes = [
    {
      'type': 'ultrasound',
      'title': 'Ultrasound Report',
      'icon': Icons.monitor,
      'color': AppTheme.primaryPurple,
    },
    {
      'type': 'blood_test',
      'title': 'Blood Test',
      'icon': Icons.bloodtype,
      'color': AppTheme.dangerRed,
    },
    {
      'type': 'medical_report',
      'title': 'Medical Report',
      'icon': Icons.description,
      'color': AppTheme.accentColor,
    },
    {
      'type': 'prescription',
      'title': 'Prescription',
      'icon': Icons.medication,
      'color': AppTheme.safeGreen,
    },
    {
      'type': 'other',
      'title': 'Other',
      'icon': Icons.folder,
      'color': AppTheme.warningOrange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _uploadAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _uploadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _uploadAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _uploadAnimationController.dispose();
    _streamSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Method to scroll to the bottom of the analysis display
  void _smartScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

void _analyzeDocument() async {
  if (selectedDocument != null) {
    setState(() {
      _isStreaming = true;
      _streamBuffer.clear();
      ref.read(documentAnalysisProvider.notifier).setIsAnalyzing(true);
      ref.read(documentAnalysisProvider.notifier).setAnalysisError(null);
      ref.read(documentAnalysisProvider.notifier).setAnalysisResult(null);
    });

    try {
      await ref.read(documentAnalysisProvider.notifier).analyzeDocument(
        documentFile: selectedDocument!,
        documentType: selectedDocumentType,
        onNewChunk: (chunk) {
          setState(() {
            _streamBuffer.write(chunk);
          });
          _smartScrollToBottom();
        },
        onComplete: (result) {
          setState(() {
            _isStreaming = false;
          });
          ref.read(documentAnalysisProvider.notifier).setIsAnalyzing(false);
          ref.read(documentAnalysisProvider.notifier).setAnalysisResult(_streamBuffer.toString());
        },
      );
    } catch (e) {
      setState(() {
        _isStreaming = false;
        _streamBuffer.clear(); // Clear any partial data
      });
      ref.read(documentAnalysisProvider.notifier).setIsAnalyzing(false);
      ref.read(documentAnalysisProvider.notifier).setAnalysisError('Error initiating analysis: $e');
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final isPremiumUser = userProfileState.userProfile?.isPremium ?? false;
    final documentState = ref.watch(documentAnalysisProvider);
    
    // Show paywall for free users
    if (!isPremiumUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const CustomPaywallDialog(
            title: 'Premium Feature',
            message: 'Document Analysis is a premium feature. Upgrade to access AI-powered medical document analysis for pregnancy safety.',
            icon: Icons.workspace_premium,
            iconColor: AppTheme.newPremiumGold,
            type: PaywallType.upgrade,
          ),
        );
      });
    }
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Document Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            onPressed: () => _showAnalysisHistory(),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController, // Attach scroll controller
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 48,
                    color: AppTheme.primaryPurple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Document Analysis',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload medical documents and get AI-powered insights personalized for your pregnancy journey',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Document Type Selection
            Text(
              'Document Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: documentTypes.length,
              itemBuilder: (context, index) {
                final docType = documentTypes[index];
                final isSelected = selectedDocumentType == docType['type'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDocumentType = docType['type'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? docType['color'].withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? docType['color']
                            : AppTheme.textSecondary.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          docType['icon'],
                          size: 32,
                          color: isSelected 
                              ? docType['color']
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          docType['title'],
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? docType['color']
                                : AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Document Upload
            Text(
              'Upload Document',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: selectedDocument != null 
                      ? AppTheme.safeGreen.withOpacity(0.1)
                      : AppTheme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedDocument != null 
                        ? AppTheme.safeGreen
                        : AppTheme.textSecondary.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: selectedDocument != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              selectedDocument!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDocument = null;
                                  _streamBuffer.clear(); // Clear previous analysis
                                  ref.read(documentAnalysisProvider.notifier).setAnalysisResult(null);
                                  ref.read(documentAnalysisProvider.notifier).setAnalysisError(null);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to upload document',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Supports JPG, PNG, PDF formats',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // What You'll Get Section (REPLACES Question Input)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primaryPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What You\'ll Get',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    '✓',
                    'Personalized analysis based on your trimester',
                  ),
                  _buildBenefitItem(
                    '✓',
                    'Safety insights for pregnancy-specific concerns',
                  ),
                  _buildBenefitItem(
                    '✓',
                    'Key findings and what they mean for you',
                  ),
                  _buildBenefitItem(
                    '✓',
                    'When to consult your healthcare provider',
                  ),
                  _buildBenefitItem(
                    '✓',
                    'Consideration of your dietary preferences & allergies',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Analyze Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: selectedDocument != null && !_isStreaming && !documentState.isAnalyzing && documentState.error == null
                    ? _analyzeDocument
                    : (documentState.error != null ? _analyzeDocument : null), // Allow retry if there's an error
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                // Show loading ONLY if streaming/analyzing AND no error
                child: (_isStreaming || documentState.isAnalyzing) && documentState.error == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Analyzing...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics),
                          const SizedBox(width: 8),
                          Text(
                            documentState.error != null ? 'Try Again' : 'Analyze Document',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            if (documentState.error != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(documentState.error!),
            ],

            const SizedBox(height: 32),

            // Analysis Result Display (Streaming or Final) - ONLY show if no error
            if (documentState.error == null)
              _buildAnalysisStreamDisplay(),
            
            if (!_isStreaming && documentState.analysisResult != null && _streamBuffer.isEmpty) ...[
              const SizedBox(height: 32),
              // If streaming ended and there's a final analysis result but no stream content (e.g. initial load)
              _buildAnalysisResult(documentState.analysisResult!),
            ],


            const SizedBox(height: 32),

            // Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important Notes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem('🔒', 'Your documents are processed securely and not stored'),
                  _buildInfoItem('🤖', 'AI analysis is for informational purposes only'),
                  _buildInfoItem('👩‍⚕️', 'Always consult your healthcare provider for medical advice'),
                  _buildInfoItem('📋', 'Results should supplement, not replace, professional care'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.safeGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for displaying errors with user-friendly messages
  Widget _buildErrorMessage(String error) {
    // Parse error type
    bool isLimitReached = error.contains('LIMIT_REACHED');
    bool isPremiumRequired = error.contains('PREMIUM_REQUIRED');
    
    String displayMessage;
    IconData icon;
    Color color;
    
    if (isLimitReached) {
      // Extract the actual message after the prefix
      displayMessage = error.replaceAll('Exception: LIMIT_REACHED:', '').trim();
      if (displayMessage.isEmpty) {
        displayMessage = 'You have reached your document analysis limit for this period.';
      }
      icon = Icons.hourglass_empty;
      color = AppTheme.warningOrange;
    } else if (isPremiumRequired) {
      displayMessage = error.replaceAll('Exception: PREMIUM_REQUIRED:', '').trim();
      if (displayMessage.isEmpty) {
        displayMessage = 'Premium subscription required for document analysis.';
      }
      icon = Icons.workspace_premium;
      color = AppTheme.newPremiumGold;
    } else {
      // Generic error - clean up the message
      displayMessage = error.replaceAll('Exception:', '').trim();
      displayMessage = displayMessage.replaceAll('Error initiating analysis:', '').trim();
      displayMessage = displayMessage.replaceAll('Failed to analyze document:', '').trim();
      if (displayMessage.isEmpty || displayMessage.contains('429') || displayMessage.contains('403')) {
        displayMessage = 'An error occurred while analyzing the document. Please try again.';
      }
      icon = Icons.error_outline;
      color = AppTheme.dangerRed;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLimitReached ? 'Limit Reached' : 
                  isPremiumRequired ? 'Premium Required' : 'Error',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayMessage,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget displaying analysis result (with streaming)
  Widget _buildAnalysisStreamDisplay() {
    // Only show if there's streaming content or if streaming just finished and has content
    if (_streamBuffer.isNotEmpty || _isStreaming) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.safeGreen.withOpacity(0.1),
              AppTheme.primaryPurple.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.safeGreen.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.safeGreen,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Streaming/Final Analysis Response
            MarkdownBody(
              data: _streamBuffer.toString(),
              selectable: true,
              styleSheet: AppMarkdownStyles.getStyleSheet(context),
              inlineSyntaxes: [HighlightSyntax()],
              builders: {'mark': HighlightBuilder()},
            ),
            
            if (_isStreaming) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppTheme.warningOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This analysis is for educational purposes. Please discuss results with your healthcare provider.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(); // Fallback when no streaming or result
    }
  }


  // This old _buildAnalysisResult is now largely replaced by _buildAnalysisStreamDisplay
  // It might still be called if a non-streaming analysis path is used, or for history display.
  // For the current task, the streaming display is primary.
  Widget _buildAnalysisResult(String analysisResult) { // Changed type to String
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.safeGreen.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.safeGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.safeGreen,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Analysis Complete',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Analysis Response (if not streaming, or after streaming is done and captured)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                MarkdownBody( // Use MarkdownBody for saved results too
                  data: analysisResult, // Directly use the string
                  selectable: true,
                  styleSheet: AppMarkdownStyles.getStyleSheet(context),
                  inlineSyntaxes: [HighlightSyntax()],
                  builders: {'mark': HighlightBuilder()},
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warningOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This analysis is for educational purposes. Please discuss results with your healthcare provider.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Select Document Source',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ✅ ADD PDF OPTION
                    _buildSourceButton(
                      icon: Icons.picture_as_pdf,
                      title: 'PDF Document',
                      subtitle: 'Choose PDF file',
                      onTap: () => _pickPDF(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSourceButton(
                            icon: Icons.camera_alt,
                            title: 'Camera',
                            subtitle: 'Take photo',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSourceButton(
                            icon: Icons.photo_library,
                            title: 'Gallery',
                            subtitle: 'Choose image',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        selectedDocument = File(pickedFile.path);
        _streamBuffer.clear(); // Clear previous analysis when new doc selected
        ref.read(documentAnalysisProvider.notifier).setAnalysisResult(null);
        ref.read(documentAnalysisProvider.notifier).setAnalysisError(null);
      });
      _uploadAnimationController.forward();
    }
  }

  // ✅ ADD PDF PICKER METHOD
  Future<void> _pickPDF() async {
    Navigator.pop(context);
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedDocument = File(result.files.single.path!);
          _streamBuffer.clear(); // Clear previous analysis when new doc selected
          ref.read(documentAnalysisProvider.notifier).setAnalysisResult(null);
          ref.read(documentAnalysisProvider.notifier).setAnalysisError(null);
        });
        _uploadAnimationController.forward();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking PDF: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  void _showAnalysisHistory() {
    // Implementation for showing analysis history
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Analysis history feature coming soon!'),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}