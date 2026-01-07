import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:safemama/features/qna/services/document_analysis_service.dart';

class DocumentAnalysisState {
  final String? analysisResult;
  final bool isAnalyzing;
  final String? error;
  final List<Map<String, dynamic>> history;
  final double uploadProgress;

  const DocumentAnalysisState({
    this.analysisResult,
    this.isAnalyzing = false,
    this.error,
    this.history = const [],
    this.uploadProgress = 0.0,
  });

  DocumentAnalysisState copyWith({
    String? analysisResult,
    bool? isAnalyzing,
    String? error,
    List<Map<String, dynamic>>? history,
    double? uploadProgress,
  }) {
    return DocumentAnalysisState(
      analysisResult: analysisResult ?? this.analysisResult,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
      history: history ?? this.history,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class DocumentAnalysisNotifier extends StateNotifier<DocumentAnalysisState> {
  final DocumentAnalysisService _service;

  DocumentAnalysisNotifier(this._service) : super(const DocumentAnalysisState()) {
    _loadAnalysisHistory();
  }

  void setIsAnalyzing(bool isAnalyzing) {
    state = state.copyWith(
      isAnalyzing: isAnalyzing,
      error: null,
    );
  }

  void setAnalysisResult(String? result) {
    state = state.copyWith(
      analysisResult: result,
      isAnalyzing: false,
      error: null,
    );
  }

  void setAnalysisError(String? error) {
    state = state.copyWith(
      error: error,
      isAnalyzing: false,
    );
  }

  Future<void> analyzeDocument({
    required File documentFile,
    required String documentType,
    String? question,
    void Function(String)? onNewChunk,
    void Function(String)? onComplete,
  }) async {
    state = state.copyWith(isAnalyzing: true, error: null, uploadProgress: 0.0, analysisResult: null);

    try {
      int progressSteps = 7;
      for (int i = 1; i <= progressSteps; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        state = state.copyWith(uploadProgress: i / progressSteps);
      }

      StringBuffer buffer = StringBuffer();
      await for (final chunk in _service.documentAnalysisStream(
        documentType: documentType,
        documentFile: documentFile,
        question: question,
      )) {
        buffer.write(chunk);
        if (onNewChunk != null) onNewChunk(chunk);
      }

      // After streaming, highlight key phrases
      final highlightedText = _highlightKeyPhrases(buffer.toString());
      state = state.copyWith(
        analysisResult: highlightedText,
        isAnalyzing: false,
        uploadProgress: 1.0,
        error: null,
      );

      if (onComplete != null) onComplete(highlightedText);

      _loadAnalysisHistory();
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
        uploadProgress: 0.0,
        analysisResult: null,
      );
    }
  }

  // Keyword highlighting for markdown
  String _highlightKeyPhrases(String text) {
    const keywords = [
      "normal", "abnormal", "warning", "summary", "consult", "doctor", "provider",
      "concern", "findings", "observations", "major", "Attention", "danger", "urgent"
    ];
    String highlighted = text;
    for (final word in keywords) {
      highlighted = highlighted.replaceAllMapped(
        RegExp(r'\b(' + RegExp.escape(word) + r')\b', caseSensitive: false),
        (m) => "<mark>${m[0]}</mark>"
      );
    }
    return highlighted;
  }

  Future<void> _loadAnalysisHistory() async {
    try {
      final history = await _service.getAnalysisHistory();
      state = state.copyWith(history: history);
    } catch (_) {}
  }

  void clearAnalysis() {
    state = state.copyWith(
      analysisResult: null,
      error: null,
      uploadProgress: 0.0,
    );
  }

  void deleteAnalysis(String analysisId) {
    final updatedHistory = state.history
        .where((analysis) => analysis['id'] != analysisId)
        .toList();
    state = state.copyWith(history: updatedHistory);
    _service.deleteAnalysis(analysisId);
  }

  Map<String, dynamic> getAnalysisStats() {
    final totalAnalyses = state.history.length;
    final documentTypes = <String, int>{};
    double averageConfidence = 0.0;

    for (final analysis in state.history) {
      final docType = analysis['document_type'] as String;
      documentTypes[docType] = (documentTypes[docType] ?? 0) + 1;
      final confidence = analysis['confidence_score'] as double? ?? 0.0;
      averageConfidence += confidence;
    }

    if (totalAnalyses > 0) {
      averageConfidence = averageConfidence / totalAnalyses;
    }

    return {
      'totalAnalyses': totalAnalyses,
      'documentTypes': documentTypes,
      'averageConfidence': averageConfidence,
      'recentAnalysis': state.history.isNotEmpty ? state.history.first : null,
    };
  }
}

final documentAnalysisServiceProvider = Provider<DocumentAnalysisService>((ref) {
  return DocumentAnalysisService();
});

final documentAnalysisProvider = StateNotifierProvider<DocumentAnalysisNotifier, DocumentAnalysisState>((ref) {
  final service = ref.watch(documentAnalysisServiceProvider);
  return DocumentAnalysisNotifier(service);
});
