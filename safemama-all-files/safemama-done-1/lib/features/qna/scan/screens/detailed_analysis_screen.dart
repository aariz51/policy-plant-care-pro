// lib/features/scan/screens/detailed_analysis_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:safemama/core/models/scan_data.dart';
import 'package:safemama/l10n/app_localizations.dart';

// A new, custom widget for our beautiful sections
class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class DetailedAnalysisScreen extends StatelessWidget {
  final ScanData scanData;
  const DetailedAnalysisScreen({super.key, required this.scanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Map<String, dynamic>? analysisData;
    String? error;

    try {
      if (scanData.rawResponse != null && scanData.rawResponse!.isNotEmpty) {
        analysisData = jsonDecode(scanData.rawResponse!);
      }
    } catch (e) {
      error = "Error displaying details: Could not parse analysis data.";
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.detailedAnalysisTitle)),
      body: error != null
          ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
          : analysisData == null
              ? Center(child: Text(scanData.explanation ?? 'No details available.'))
              : _buildAnalysisContent(context, analysisData, theme),
    );
  }

  Widget _buildAnalysisContent(BuildContext context, Map<String, dynamic> data, ThemeData theme) {
    final productName = data['productName'] ?? 'Product Analysis';
    final List<Widget> sections = [];

    // Summary Section
    if (data['summary'] != null) {
      sections.add(InfoCard(
        title: 'Summary',
        content: data['summary'],
        icon: Icons.info_outline,
        iconColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
      ));
    }
    
    // Warnings Section
    final warnings = data['warnings'] as List?;
    if (warnings != null && warnings.isNotEmpty) {
      sections.add(InfoCard(
        title: 'Warnings',
        content: warnings.map((w) => '• $w').join('\n'),
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange.shade800,
        backgroundColor: Colors.orange.withOpacity(0.1),
      ));
    }

    // Myth Buster Section (It's back!)
    final mythBuster = data['mythBuster'] as Map?;
    if (mythBuster != null && mythBuster['myth'] != null) {
       sections.add(InfoCard(
        title: 'Pregnancy Myth Buster',
        content: 'Myth: "${mythBuster['myth']}"\n\nFact: ${mythBuster['fact']}',
        icon: Icons.psychology_outlined,
        iconColor: Colors.purple,
        backgroundColor: Colors.purple.withOpacity(0.1),
      ));
    }

    // Deep Dive Section
    final deepDive = data['deepDive'] as Map?;
    if (deepDive != null && deepDive['title'] != null) {
      sections.add(InfoCard(
        title: deepDive['title'],
        content: deepDive['content'],
        icon: Icons.science_outlined,
        iconColor: Colors.teal,
        backgroundColor: Colors.teal.withOpacity(0.1),
      ));
    }

    // Questions for Doctor Section
    final doctorQuestions = data['questionsForDoctor'] as List?;
    if (doctorQuestions != null && doctorQuestions.isNotEmpty) {
      sections.add(InfoCard(
        title: 'Questions for Your Doctor',
        content: doctorQuestions.map((q) => '• $q').join('\n'),
        icon: Icons.medical_services_outlined,
        iconColor: Colors.blue.shade700,
        backgroundColor: Colors.blue.withOpacity(0.1),
      ));
    }
    
    // Tip Section
    if (data['pregnancyTip'] != null) {
       sections.add(InfoCard(
        title: 'SafeMama Tip',
        content: data['pregnancyTip'],
        icon: Icons.lightbulb_outline,
        iconColor: Colors.green.shade800,
        backgroundColor: Colors.green.withOpacity(0.15),
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(productName, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 24, thickness: 1),
        ...sections,
      ],
    );
  }
}