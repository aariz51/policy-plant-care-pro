// lib/features/guide/screens/guide_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:safemama/core/models/guide_model.dart';
import 'package:safemama/core/ui/app_markdown_styles.dart';
import 'package:safemama/core/ui/markdown_highlight_syntax.dart';

class GuideDetailScreen extends StatelessWidget {
  final Guide guide;

  const GuideDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
      ),
      body: Markdown(
        data: guide.contentMarkdown,
        selectable: true,
        styleSheet: AppMarkdownStyles.getStyleSheet(context),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        
        // ============ THE CORRECTED CODE IS HERE ============
        inlineSyntaxes: [
          HighlightSyntax(),
        ],
        builders: {
          'mark': HighlightBuilder(),
        },
        // ==================================================
      ),
    );
  }
}