// lib/features/pregnancy_tools/screens/pregnancy_test_checker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
import 'package:safemama/features/pregnancy_tools/providers/pregnancy_test_ai_provider.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:intl/intl.dart';

class PregnancyTestCheckerScreen extends ConsumerStatefulWidget {
  const PregnancyTestCheckerScreen({super.key});

  @override
  ConsumerState<PregnancyTestCheckerScreen> createState() =>
      _PregnancyTestCheckerScreenState();
}

class _PregnancyTestCheckerScreenState
    extends ConsumerState<PregnancyTestCheckerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  DateTime? _lmpDate;
  int _cycleLength = 28;
  final List<DateTime> _unprotectedSexDates = [];
  final List<String> _selectedSymptoms = [];
  bool _testTaken = false;
  DateTime? _testTakenDate;
  String? _testResult;
  int _anxietyLevel = 3;
  final TextEditingController _notesController = TextEditingController();

  // Common pregnancy symptoms
  final List<String> _availableSymptoms = [
    'Missed period',
    'Nausea or vomiting',
    'Breast tenderness',
    'Fatigue',
    'Frequent urination',
    'Mood swings',
    'Light spotting',
    'Cramping',
    'Bloating',
    'Food aversions',
    'Heightened sense of smell',
    'None of these',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPremiumAccess();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _checkPremiumAccess() {
    final userProfile = ref.read(userProfileNotifierProvider);
    final isPremium = userProfile.userProfile?.isPremiumUser ?? false;

    if (!isPremium) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomPaywallDialog(
          title: 'Premium Feature',
          message:
              'Pregnancy Test Checker is a premium-only feature. Get AI-powered pregnancy likelihood assessment based on your cycle, symptoms, and test results.',
          icon: Icons.pregnant_woman,
          iconColor: AppTheme.primaryPurple,
          type: PaywallType.upgrade,
        ),
      );
    }
  }

  Future<void> _selectLMPDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lmpDate ?? DateTime.now().subtract(const Duration(days: 28)),
      firstDate: DateTime.now().subtract(const Duration(days: 120)),
      lastDate: DateTime.now(),
      helpText: 'Select Last Menstrual Period',
    );

    if (picked != null) {
      setState(() {
        _lmpDate = picked;
      });
    }
  }

  Future<void> _addUnprotectedSexDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
      helpText: 'Select Date',
    );

    if (picked != null && !_unprotectedSexDates.contains(picked)) {
      setState(() {
        _unprotectedSexDates.add(picked);
        _unprotectedSexDates.sort((a, b) => b.compareTo(a)); // Most recent first
      });
    }
  }

  Future<void> _selectTestDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _testTakenDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      helpText: 'Select Test Date',
    );

    if (picked != null) {
      setState(() {
        _testTakenDate = picked;
      });
    }
  }

  void _submitAnalysis() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lmpDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your last menstrual period date'),
          backgroundColor: AppTheme.avoidRed,
        ),
      );
      return;
    }

    if (_unprotectedSexDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one intimate date'),
          backgroundColor: AppTheme.avoidRed,
        ),
      );
      return;
    }

    // Call the AI analysis
    await ref.read(pregnancyTestAIProvider.notifier).analyzePregnancyTest(
          lmpDate: DateFormat('yyyy-MM-dd').format(_lmpDate!),
          cycleLength: _cycleLength,
          hadUnprotectedSexDates: _unprotectedSexDates
              .map((date) => DateFormat('yyyy-MM-dd').format(date))
              .toList(),
          symptoms: _selectedSymptoms,
          testTaken: _testTaken,
          testTakenDate:
              _testTakenDate != null ? DateFormat('yyyy-MM-dd').format(_testTakenDate!) : null,
          testResult: _testResult,
          anxietyLevel: _anxietyLevel,
          notes: _notesController.text.trim(),
        );

    // Check state after analysis
    final state = ref.read(pregnancyTestAIProvider);

    if (state.isPremiumRequired) {
      showDialog(
        context: context,
        builder: (context) => const CustomPaywallDialog(
          title: 'Premium Feature',
          message:
              'Pregnancy Test Checker is only available for premium members.',
          icon: Icons.pregnant_woman,
          iconColor: AppTheme.primaryPurple,
          type: PaywallType.upgrade,
        ),
      );
    } else if (state.limitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Usage limit reached'),
          backgroundColor: AppTheme.avoidRed,
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: AppTheme.avoidRed,
        ),
      );
    } else if (state.analysis != null) {
      // Success - show results
      _showResultsDialog(state.analysis!);
    }
  }

  void _showResultsDialog(PregnancyTestAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getLikelihoodColor(analysis.likelihood),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.pregnant_woman, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      'Pregnancy Likelihood',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        analysis.likelihood.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is educational information only, not medical diagnosis. Always take a home pregnancy test and consult your healthcare provider.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary
                    _buildResultSection(
                      'Summary',
                      analysis.summary,
                      Icons.summarize,
                      AppTheme.primaryBlue,
                    ),

                    // Next Steps
                    _buildResultSection(
                      'Next Steps',
                      analysis.nextSteps,
                      Icons.directions_walk,
                      AppTheme.safeGreen,
                    ),

                    // When to Test
                    _buildResultSection(
                      'When to Test',
                      analysis.whenToTest,
                      Icons.calendar_today,
                      AppTheme.primaryPurple,
                    ),

                    // Urgent Warnings
                    if (analysis.urgentWarnings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.avoidRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.avoidRed.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning, color: AppTheme.avoidRed, size: 20),
                                const SizedBox(width: 8),
                                Text('⚠️ Urgent Warnings',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.avoidRed, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...analysis.urgentWarnings
                                .map((warning) => Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ', style: TextStyle(fontSize: 16)),
                                          Expanded(child: Text(warning)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),
                    ],

                    // Reassurance
                    if (analysis.reassuranceNote.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.safeGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.favorite, color: AppTheme.safeGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                analysis.reassuranceNote,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Usage info
                    const SizedBox(height: 16),
                    Text(
                      'Usage: ${analysis.currentUsage}/${analysis.limit} per ${analysis.period}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Color _getLikelihoodColor(String likelihood) {
    switch (likelihood.toLowerCase()) {
      case 'high':
        return AppTheme.avoidRed;
      case 'medium':
        return AppTheme.warningOrange;
      case 'low':
      default:
        return AppTheme.safeGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(pregnancyTestAIProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Pregnancy Test Checker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: aiState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryPurple),
                  const SizedBox(height: 16),
                  Text('Analyzing your data...', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disclaimer card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.primaryPurple, size: 32),
                          const SizedBox(height: 12),
                          Text(
                            'AI-Powered Pregnancy Likelihood Assessment',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get personalized insights based on your cycle, symptoms, and test results. This is educational only and not a medical diagnosis.',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // LMP Date
                    Text('Last Menstrual Period *', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectLMPDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _lmpDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_lmpDate!)
                                  : 'Select date',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Icon(Icons.calendar_today, color: AppTheme.primaryPurple),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cycle Length
                    Text('Average Cycle Length (days)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _cycleLength.toDouble(),
                            min: 21,
                            max: 35,
                            divisions: 14,
                            activeColor: AppTheme.primaryPurple,
                            label: '$_cycleLength days',
                            onChanged: (value) {
                              setState(() {
                                _cycleLength = value.toInt();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_cycleLength days',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryPurple),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Intimate Dates
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Intimate Dates *', style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          onPressed: _addUnprotectedSexDate,
                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryPurple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_unprotectedSexDates.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child:                         Text(
                          'Tap + to add dates',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _unprotectedSexDates
                            .map((date) => Chip(
                                  label: Text(DateFormat('MMM dd').format(date)),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () {
                                    setState(() {
                                      _unprotectedSexDates.remove(date);
                                    });
                                  },
                                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 20),

                    // Symptoms
                    Text('Current Symptoms', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSymptoms
                          .map((symptom) => FilterChip(
                                label: Text(symptom),
                                selected: _selectedSymptoms.contains(symptom),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSymptoms.add(symptom);
                                    } else {
                                      _selectedSymptoms.remove(symptom);
                                    }
                                  });
                                },
                                selectedColor: AppTheme.primaryPurple.withOpacity(0.3),
                                checkmarkColor: AppTheme.primaryPurple,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),

                    // Home Test Taken
                    Row(
                      children: [
                        Expanded(
                          child: Text('Have you taken a home pregnancy test?', style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Switch(
                          value: _testTaken,
                          onChanged: (value) {
                            setState(() {
                              _testTaken = value;
                              if (!value) {
                                _testTakenDate = null;
                                _testResult = null;
                              }
                            });
                          },
                          activeColor: AppTheme.primaryPurple,
                        ),
                      ],
                    ),

                    if (_testTaken) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectTestDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _testTakenDate != null
                                    ? 'Test date: ${DateFormat('MMM dd, yyyy').format(_testTakenDate!)}'
                                    : 'Select test date',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Icon(Icons.calendar_today, color: AppTheme.primaryPurple),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Test Result', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _testResult,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.dividerColor),
                          ),
                        ),
                        hint: const Text('Select result'),
                        items: const [
                          DropdownMenuItem(value: 'positive', child: Text('Positive')),
                          DropdownMenuItem(value: 'negative', child: Text('Negative')),
                          DropdownMenuItem(value: 'faint', child: Text('Faint line')),
                          DropdownMenuItem(value: 'invalid', child: Text('Invalid/Unclear')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _testResult = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Anxiety Level
                    Text('How anxious are you feeling?', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _anxietyLevel.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            activeColor: AppTheme.primaryPurple,
                            label: _getAnxietyLabel(_anxietyLevel),
                            onChanged: (value) {
                              setState(() {
                                _anxietyLevel = value.toInt();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getAnxietyLabel(_anxietyLevel),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryPurple),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notes - Enhanced for better user input
                    Text('Describe Your Experience (optional)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Share any other symptoms, feelings, or concerns to get a more personalized analysis',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'E.g., "I\'ve been feeling unusually tired and had some light spotting. My breasts feel sore. I also noticed food smells make me feel nauseous..."',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: aiState.isLoading ? null : _submitAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Analyze',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getAnxietyLabel(int level) {
    switch (level) {
      case 1:
        return 'Calm';
      case 2:
        return 'Slightly anxious';
      case 3:
        return 'Moderately anxious';
      case 4:
        return 'Very anxious';
      case 5:
        return 'Extremely anxious';
      default:
        return 'Moderate';
    }
  }
}

