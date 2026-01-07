// lib/core/widgets/full_screen_loading_route_widget.dart
import 'package:flutter/material.dart';
import 'package:safemama/core/widgets/rich_animated_loading_widget.dart';

class FullScreenLoadingRouteWidget extends StatelessWidget {
  final List<String> texts;
  final String initialText;
  // final String? heartIconSvgPath; // REMOVE

  const FullScreenLoadingRouteWidget({
    super.key,
    required this.texts,
    required this.initialText,
    // this.heartIconSvgPath, // REMOVE
  });

  @override
  Widget build(BuildContext context) {
    // RichAnimatedLoadingWidget itself is now a full Scaffold
    return RichAnimatedLoadingWidget(
      loadingTexts: texts,
      initialText: initialText,
      // heartIconSvgPath: heartIconSvgPath, // REMOVE
    );
  }
}