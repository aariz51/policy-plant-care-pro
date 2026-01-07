// lib/features/guide/providers/ai_guide_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/providers/app_providers.dart';

// <<< CHANGED: The state is now empty. All UI state will be managed locally in the screen.
class AiGuideState {
  AiGuideState();
}

// <<< CHANGED: The notifier is much simpler. It no longer handles the stream.
// Its only job is to perform actions after the guide is successfully generated.
class AiGuideNotifier extends StateNotifier<AiGuideState> {
  final Ref _ref;

  AiGuideNotifier(this._ref) : super(AiGuideState());

  // This method will be called from the screen *after* the stream is complete.
  void guideGenerationComplete() {
    _ref.read(userProfileNotifierProvider.notifier).incrementPersonalizedGuideCount();
  }

  // The stream subscription is no longer needed here.
  @override
  void dispose() {
    super.dispose();
  }
}

// <<< CHANGED: The provider remains, but its notifier is now much simpler.
final aiGuideProvider = StateNotifierProvider.autoDispose<AiGuideNotifier, AiGuideState>((ref) {
  return AiGuideNotifier(ref);
});