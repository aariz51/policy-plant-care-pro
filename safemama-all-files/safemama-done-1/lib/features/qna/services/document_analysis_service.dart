import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';
import 'package:safemama/core/services/openai_service.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/constants/app_constants.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class DocumentAnalysisService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();
  final OpenAIService _openAIService = OpenAIService();
  final ApiService _apiService = ApiService();

  // Compress document for better upload and OCR processing
  Future<File> _compressDocument(File file) async {
    print('🔵 [COMPRESS] Starting compression for: ${file.path}');
    final originalSize = file.lengthSync();
    print('🔵 [COMPRESS] Original file size: $originalSize bytes');

    final fileExtension = file.path.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
      try {
        final dir = file.parent;
        final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.$fileExtension';

        // Use higher quality (85) and larger dimensions for better OCR on backend
        print('🔵 [COMPRESS] Attempting compression with quality: 85, minWidth: 1500, minHeight: 1500');

        XFile? xfile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 85, // Higher quality for better OCR
          minWidth: 1500, // Larger for better text recognition
          minHeight: 1500,
        );

        if (xfile != null) {
          File compressedFile = File(xfile.path);
          final compressedSize = compressedFile.lengthSync();
          final reductionPercent = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);

          print('✅ [COMPRESS] Compression SUCCESS!');
          print('✅ [COMPRESS] Compressed file size: $compressedSize bytes');
          print('✅ [COMPRESS] Size reduction: $reductionPercent%');
          print('✅ [COMPRESS] Compressed file path: ${compressedFile.path}');

          return compressedFile;
        } else {
          print('⚠️ [COMPRESS] FlutterImageCompress returned null, using original file');
          return file;
        }
      } catch (e) {
        print('❌ [COMPRESS] Compression FAILED with error: $e');
        print('❌ [COMPRESS] Falling back to original file');
        return file;
      }
    } else {
      print('ℹ️ [COMPRESS] File type not eligible for compression (.$fileExtension), using original');
      return file;
    }
  }

  Future<Map<String, dynamic>> analyzeDocumentMultipart({
    required File documentFile,
    required String documentType,
    String? question,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Authentication required');

    // Use AppConstants directly instead of _apiService.baseUrl
    final Uri uri = Uri.parse('${AppConstants.yourBackendBaseUrl}/api/analyze-document');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['documentType'] = documentType;
    if (question != null) request.fields['question'] = question;

    final mimeType = lookupMimeType(documentFile.path) ?? 'application/octet-stream';

    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        documentFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Document analysis failed: ${response.body}');
    }
  }

  // UPDATED: Streaming analysis - sends image to backend for OCR processing
  Stream<String> documentAnalysisStream({
    required String documentType,
    required File documentFile,
    String? question,
  }) async* {
    try {
      print('🚀 [STREAM] Starting document analysis stream (Backend OCR)');
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('Authentication required');

      // Step 1: Compress the document for upload
      print('📦 [STREAM] Step 1: Compressing document for upload...');
      final File compressedFile = await _compressDocument(documentFile);
      final finalSize = compressedFile.lengthSync();
      print('📦 [STREAM] Compression complete. Final size: $finalSize bytes');

      // Step 2: Upload image to backend for OCR processing
      print('📤 [STREAM] Step 2: Uploading image to backend for OCR...');
      
      final uri = Uri.parse('${AppConstants.yourBackendBaseUrl}/api/analyze-document-stream');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['documentType'] = documentType;
      if (question != null && question.isNotEmpty) {
        request.fields['question'] = question;
      }
      
      // Get mime type
      final mimeType = lookupMimeType(compressedFile.path) ?? 'image/jpeg';
      final mimeTypeParts = mimeType.split('/');
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'document',
          compressedFile.path,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );

      print('🔍 [STREAM] Sending to backend - OCR will be performed server-side...');
      
      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        print('❌ [STREAM] Backend error: $errorBody');
        
        // Parse error response for user-friendly message
        if (streamedResponse.statusCode == 429) {
          try {
            final errorJson = json.decode(errorBody);
            final errorMessage = errorJson['error'] ?? 'You have reached your document analysis limit for this period.';
            throw Exception('LIMIT_REACHED: $errorMessage');
          } catch (e) {
            if (e.toString().contains('LIMIT_REACHED')) rethrow;
            throw Exception('LIMIT_REACHED: You have reached your document analysis limit for this period.');
          }
        } else if (streamedResponse.statusCode == 403) {
          try {
            final errorJson = json.decode(errorBody);
            final errorMessage = errorJson['error'] ?? 'Premium subscription required for document analysis.';
            throw Exception('PREMIUM_REQUIRED: $errorMessage');
          } catch (e) {
            if (e.toString().contains('PREMIUM_REQUIRED')) rethrow;
            throw Exception('PREMIUM_REQUIRED: Premium subscription required for document analysis.');
          }
        }
        throw Exception('Analysis failed: ${streamedResponse.statusCode}');
      }

      print('✅ [STREAM] Receiving streamed analysis from backend...');
      
      // Stream the response chunks
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        yield chunk;
      }

      print('✅ [STREAM] Analysis streaming complete');
    } catch (e) {
      print('❌ [STREAM] Error during streaming: $e');
      throw Exception('Failed to analyze document: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeDocument({
    required File documentFile,
    required String documentType,
    String? question,
  }) async {
    try {
      // Use the multipart method that works
      return await analyzeDocumentMultipart(
        documentFile: documentFile,
        documentType: documentType,
        question: question,
      );
    } catch (e) {
      throw Exception('Failed to analyze document: $e');
    }
  }

  Future<Map<String, dynamic>> _analyzeDocumentWithAI({
    required File documentFile,
    required String documentType,
    String? question,
  }) async {
    try {
      final bytes = await documentFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = _buildAnalysisPrompt(documentType, question);

      final response = await _openAIService.analyzeImageWithGPT4Vision(
        base64Image,
        prompt,
      );

      final confidenceScore = _calculateConfidenceScore(response);

      return {
        'response': response,
        'confidenceScore': confidenceScore,
        'analysisType': 'ai_vision',
        'model': 'gpt-4-vision-preview',
      };
    } catch (e) {
      throw Exception('AI analysis failed: $e');
    }
  }

  String _buildAnalysisPrompt(String documentType, String? question) {
    final basePrompt = '''
You are a medical AI assistant specializing in pregnancy health. Analyze this ${documentType.toLowerCase()} document and provide helpful insights for pregnancy safety.

IMPORTANT GUIDELINES:
1. Always recommend consulting healthcare providers for medical decisions
2. Focus on pregnancy-specific considerations
3. Be clear about limitations of document analysis
4. Provide educational information, not medical diagnosis
5. Highlight any concerning findings that need immediate attention

Document Type: $documentType
''';

    if (question != null && question.isNotEmpty) {
      return '''$basePrompt

Specific Question: $question

Please analyze the document with particular attention to the question asked, while following the guidelines above.''';
    }

    return '''$basePrompt

Please provide a comprehensive analysis of this document, focusing on:
- Key findings relevant to pregnancy
- Safety considerations
- When to consult healthcare provider
- Educational insights about the results''';
  }

  double _calculateConfidenceScore(String response) {
    double score = 0.7;

    if (response.length > 200) score += 0.1;
    if (response.length > 500) score += 0.1;

    final medicalTerms = ['normal', 'abnormal', 'within range', 'elevated', 'low', 'high'];
    int termCount = 0;
    for (final term in medicalTerms) {
      if (response.toLowerCase().contains(term)) termCount++;
    }
    score += (termCount * 0.02).clamp(0.0, 0.1);

    return score.clamp(0.0, 1.0);
  }

  Future<void> _saveAnalysisLocally(Map<String, dynamic> analysisData) async {
    try {
      final List<Map<String, dynamic>> localAnalyses = await getAnalysisHistory();
      localAnalyses.insert(0, analysisData);

      if (localAnalyses.length > 50) {
        localAnalyses.removeRange(50, localAnalyses.length);
      }

      await _storageService.setString('document_analyses',
          localAnalyses.toString());
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getAnalysisHistory() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        final response = await _supabase
            .from('document_analysis')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(20);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getAnalysisHistoryLocally();
    } catch (e) {
      return await _getAnalysisHistoryLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getAnalysisHistoryLocally() async {
    try {
      final analysesStr = await _storageService.getString('document_analyses');
      if (analysesStr != null) {
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteAnalysis(String analysisId) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        await _supabase
            .from('document_analysis')
            .delete()
            .eq('id', analysisId)
            .eq('user_id', user.id);
      }

      final analyses = await _getAnalysisHistoryLocally();
      analyses.removeWhere((analysis) => analysis['id'] == analysisId);

      await _storageService.setString('document_analyses',
          analyses.toString());
    } catch (e) {
      // Handle error silently
    }
  }

  Future<Map<String, dynamic>?> getAnalysisById(String analysisId) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        final response = await _supabase
            .from('document_analysis')
            .select()
            .eq('id', analysisId)
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null) {
          return Map<String, dynamic>.from(response);
        }
      }

      final analyses = await _getAnalysisHistoryLocally();
      return analyses
          .where((analysis) => analysis['id'] == analysisId)
          .firstOrNull;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAnalysesByDocumentType(String documentType) async {
    try {
      final allAnalyses = await getAnalysisHistory();
      return allAnalyses
          .where((analysis) => analysis['document_type'] == documentType)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateAnalysisNote(String analysisId, String note) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        await _supabase
            .from('document_analysis')
            .update({'user_note': note, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', analysisId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
