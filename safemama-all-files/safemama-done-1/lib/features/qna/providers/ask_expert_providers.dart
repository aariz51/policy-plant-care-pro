import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:safemama/features/qna/services/document_analysis_service.dart';

class DocumentAnalysisState {
  final Map<String, dynamic>? analysis;
  final List<Map<String, dynamic>> analysisHistory;
  final bool isLoading;
  final String? error;
  final double uploadProgress;

  const DocumentAnalysisState({
    this.analysis,
    this.analysisHistory = const [],
    this.isLoading = false,
    this.error,
    this.uploadProgress = 0.0,
  });

  DocumentAnalysisState copyWith({
    Map<String, dynamic>? analysis,
    List<Map<String, dynamic>>? analysisHistory,
    bool? isLoading,
    String? error,
    double? uploadProgress,
  }) {
    return DocumentAnalysisState(
      analysis: analysis ?? this.analysis,
      analysisHistory: analysisHistory ?? this.analysisHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class DocumentAnalysisNotifier extends StateNotifier<DocumentAnalysisState> {
  final DocumentAnalysisService _service;

  DocumentAnalysisNotifier(this._service) : super(const DocumentAnalysisState()) {
    _loadAnalysisHistory();
  }

  Future<void> analyzeDocument({
    required File documentFile,
    required String documentType,
    String? question,
  }) async {
    state = state.copyWith(isLoading: true, error: null, uploadProgress: 0.0);

    try {
      // Simulate upload progress
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        state = state.copyWith(uploadProgress: i * 0.2);
      }

      final analysis = await _service.analyzeDocument(
        documentFile: documentFile,
        documentType: documentType,
        question: question,
      );

      state = state.copyWith(
        analysis: analysis,
        isLoading: false,
        uploadProgress: 1.0,
      );

      // Add to history
      final updatedHistory = [analysis, ...state.analysisHistory];
      state = state.copyWith(analysisHistory: updatedHistory);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        uploadProgress: 0.0,
      );
    }
  }

  Future<void> _loadAnalysisHistory() async {
    try {
      final history = await _service.getAnalysisHistory();
      state = state.copyWith(analysisHistory: history);
    } catch (e) {
      // Handle error silently for history
    }
  }

  void clearAnalysis() {
    state = state.copyWith(
      analysis: null,
      error: null,
      uploadProgress: 0.0,
    );
  }

  void deleteAnalysis(String analysisId) {
    final updatedHistory = state.analysisHistory
        .where((analysis) => analysis['id'] != analysisId)
        .toList();
    
    state = state.copyWith(analysisHistory: updatedHistory);
    _service.deleteAnalysis(analysisId);
  }

  Map<String, dynamic> getAnalysisStats() {
    final totalAnalyses = state.analysisHistory.length;
    final documentTypes = <String, int>{};
    double averageConfidence = 0.0;

    for (final analysis in state.analysisHistory) {
      final docType = analysis['documentType'] as String;
      documentTypes[docType] = (documentTypes[docType] ?? 0) + 1;
      
      final confidence = analysis['confidenceScore'] as double? ?? 0.0;
      averageConfidence += confidence;
    }

    if (totalAnalyses > 0) {
      averageConfidence = averageConfidence / totalAnalyses;
    }

    return {
      'totalAnalyses': totalAnalyses,
      'documentTypes': documentTypes,
      'averageConfidence': averageConfidence,
      'recentAnalysis': state.analysisHistory.isNotEmpty ? state.analysisHistory.first : null,
    };
  }
}

// Providers
final documentAnalysisServiceProvider = Provider<DocumentAnalysisService>((ref) {
  return DocumentAnalysisService();
});

final documentAnalysisProvider = StateNotifierProvider<DocumentAnalysisNotifier, DocumentAnalysisState>((ref) {
  final service = ref.watch(documentAnalysisServiceProvider);
  return DocumentAnalysisNotifier(service);
});
