// lib/core/ui/app_markdown_styles.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AppMarkdownStyles {
  static MarkdownStyleSheet getStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      h2: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, height: 2, color: theme.colorScheme.primary),
      p: theme.textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 16),
      blockquote: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8.0),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.secondary,
            width: 5,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(16),
      listBulletPadding: const EdgeInsets.only(top: 5, left: 16),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}