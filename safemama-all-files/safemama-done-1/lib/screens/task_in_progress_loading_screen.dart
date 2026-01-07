// lib/screens/task_in_progress_loading_screen.dart
import 'package:flutter/material.dart';
import 'package:safemama/l10n/app_localizations.dart';

class TaskInProgressLoadingScreen extends StatelessWidget {
  const TaskInProgressLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              S.taskInProgressLoadingMessage ?? 'Processing...', // Use a fallback
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}