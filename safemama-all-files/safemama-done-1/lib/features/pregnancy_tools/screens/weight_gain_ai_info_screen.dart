import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'dart:convert';

class WeightGainAIInfoScreen extends ConsumerStatefulWidget {
  final double currentWeight;
  final double prePregnancyWeight;
  final int currentWeek;
  final double height;
  final String bmiCategory;

  const WeightGainAIInfoScreen({
    Key? key,
    required this.currentWeight,
    required this.prePregnancyWeight,
    required this.currentWeek,
    required this.height,
    required this.bmiCategory,
  }) : super(key: key);

  @override
  ConsumerState<WeightGainAIInfoScreen> createState() => _WeightGainAIInfoScreenState();
}

class _WeightGainAIInfoScreenState extends ConsumerState<WeightGainAIInfoScreen> {
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
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Use streaming endpoint
      final stream = apiService.postStream(
        '/pregnancy-tools/weight-gain-tracker-ai',
        {
          'currentWeight': widget.currentWeight,
          'prePregnancyWeight': widget.prePregnancyWeight,
          'currentWeek': widget.currentWeek,
          'height': widget.height,
          'bmi': widget.bmiCategory,
        },
      );

      await for (final chunk in stream) {
        if (!mounted) return;
        
        // Parse SSE format
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            try {
              final data = jsonDecode(jsonStr);
              if (data['text'] != null) {
                setState(() {
                  _streamedContent += data['text'];
                  _isLoading = false;
                });
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Weight Gain Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          if (!_isLoading && !_hasError)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Add share functionality
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
            Icon(Icons.error_outline, size: 64, color: AppTheme.dangerRed),
            const SizedBox(height: 16),
            const Text('Failed to load AI analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.monitor_weight, size: 40, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weight Gain Analysis',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Week ${widget.currentWeek} • AI-Powered',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content
          if (_isLoading && _streamedContent.isEmpty)
            Column(
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading AI analysis...'),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: MarkdownBody(
                data: _streamedContent.isNotEmpty ? _streamedContent : 'Generating analysis...',
                styleSheet: MarkdownStyleSheet(
                  h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  p: const TextStyle(fontSize: 16, height: 1.6),
                  strong: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  listBullet: TextStyle(color: Colors.green.shade700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
