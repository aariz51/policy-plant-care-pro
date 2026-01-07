// lib/core/services/api_service.dart (WITH NEW STREAMING METHOD + GENERIC HELPERS)

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';
import 'package:safemama/core/constants/app_constants.dart';
import 'package:safemama/core/models/guide_model.dart';
import 'package:safemama/core/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:functions_client/functions_client.dart';

class ApiService {
  final String _baseUrl = AppConstants.yourBackendBaseUrl;

  ApiService() {
    print('🔧 [ApiService] Initialized with base URL: $_baseUrl');
    print('🔧 [ApiService] Base URL from constants: ${AppConstants.yourBackendBaseUrl}');
    _testConnectivity();
  }

  // Test basic connectivity on initialization
  void _testConnectivity() async {
    try {
      print('\n🧪 [ApiService] ========== CONNECTIVITY TEST START ==========');
      print('📍 [ApiService] Target: $_baseUrl/api/test-connection');
      print('⏱️ [ApiService] Timeout: 10 seconds');
      
      final uri = Uri.parse('$_baseUrl/api/test-connection');
      print('✅ [ApiService] URI parsed: $uri');
      
      print('🌐 [ApiService] Attempting HTTP GET request...');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ [ApiService] Request timed out after 10 seconds');
          throw TimeoutException('Request timed out');
        },
      );
      
      print('📡 [ApiService] Response received! Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅✅✅ [ApiService] BACKEND IS REACHABLE!');
        print('📦 [ApiService] Response: ${response.body}');
      } else {
        print('⚠️ [ApiService] Backend responded with status: ${response.statusCode}');
        print('📦 [ApiService] Body: ${response.body}');
      }
    } on SocketException catch (e) {
      print('❌ [ApiService] SocketException - Network unreachable');
      print('📛 [ApiService] Error: ${e.message}');
      print('💡 [ApiService] This usually means:');
      print('   - Backend is not running on $_baseUrl');
      print('   - Phone and laptop are on different WiFi networks');
      print('   - Firewall is blocking port 3001');
    } on TimeoutException catch (e) {
      print('❌ [ApiService] TimeoutException - Request took too long');
      print('📛 [ApiService] Error: $e');
      print('💡 [ApiService] Backend may be slow or unreachable');
    } on HttpException catch (e) {
      print('❌ [ApiService] HttpException - HTTP protocol error');
      print('📛 [ApiService] Error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌❌❌ [ApiService] Connectivity test FAILED: $e');
      print('📚 [ApiService] Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      print('💡 [ApiService] Backend should be at: $_baseUrl');
    } finally {
      print('🏁 [ApiService] ========== CONNECTIVITY TEST END ==========\n');
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      print('🔑 [ApiService] Getting auth token...');
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      if (token != null) {
        print('✅ [ApiService] Auth token obtained (length: ${token.length})');
      } else {
        print('❌ [ApiService] No auth token available');
      }
      return token;
    } catch (e) {
      print('❌ [ApiService] Error getting auth token: $e');
      return null;
    }
  }

  // ===================================================================
  // ================ GENERIC HELPER METHODS (NEW) =====================
  // ===================================================================

  // Generic POST request helper
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? additionalHeaders,
  }) async {
    print('\n🚀 [ApiService] ========== POST REQUEST START ==========');
    print('📍 [ApiService] Base URL: $_baseUrl');
    print('📍 [ApiService] Endpoint: $endpoint');
    print('📍 [ApiService] Full URL: $_baseUrl$endpoint');
    print('📦 [ApiService] Body: ${jsonEncode(body)}');
    
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [ApiService] POST failed: No auth token');
        throw Exception('Authentication required. Please log in again.');
      }

      final fullUrl = '$_baseUrl$endpoint';
      print('🌐 [ApiService] Parsing URI: $fullUrl');
      final uri = Uri.parse(fullUrl);
      print('✅ [ApiService] URI parsed successfully: $uri');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.substring(0, 20)}...', // Log partial token
        ...?additionalHeaders,
      };
      print('📋 [ApiService] Headers prepared (token truncated for security)');

      final requestBody = jsonEncode(body);
      print('📝 [ApiService] Request body encoded, length: ${requestBody.length}');

      print('⏳ [ApiService] Sending HTTP POST request...');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              ...?additionalHeaders,
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              print('⏱️ [ApiService] Request timed out after 60 seconds');
              throw Exception('Request timed out');
            },
          );

      print('✅ [ApiService] Response received!');
      print('📊 [ApiService] Status code: ${response.statusCode}');
      print('📄 [ApiService] Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        print('✅ [ApiService] POST SUCCESS');
        print('🚀 [ApiService] ========== POST REQUEST END ==========\n');
        return decoded;
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        print('❌ [ApiService] 403 Forbidden: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Access denied');
      } else if (response.statusCode == 401) {
        print('❌ [ApiService] 401 Unauthorized');
        throw Exception('Session expired. Please log in again.');
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [ApiService] Error ${response.statusCode}: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Request failed');
      }
    } on SocketException catch (e) {
      print('❌ [ApiService] SocketException: $e');
      print('💡 [ApiService] This usually means the backend server is not reachable');
      throw Exception('Network error. Please check your connection.');
    } on http.ClientException catch (e) {
      print('❌ [ApiService] ClientException: $e');
      throw Exception('Connection failed. Please try again.');
    } on TimeoutException catch (e) {
      print('❌ [ApiService] TimeoutException: $e');
      throw Exception('Request timed out. Please try again.');
    } on FormatException catch (e) {
      print('❌ [ApiService] FormatException: $e');
      throw Exception('Invalid response format from server.');
    } catch (e, stackTrace) {
      print('❌ [ApiService] Unexpected error: $e');
      print('📚 [ApiService] Stack trace: $stackTrace');
      print('🚀 [ApiService] ========== POST REQUEST FAILED ==========\n');
      rethrow;
    }
  }

  // Generic POST with file upload
  Future<Map<String, dynamic>> postWithFile(
    String endpoint,
    File file, {
    required Map<String, String> fields,
  }) async {
    try {
      print('[ApiService] POST with file to: $_baseUrl$endpoint');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required. Please log in again.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$endpoint'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath('document', file.path));

      print('[ApiService] Uploading file: ${file.path}');
      print('[ApiService] Fields: $fields');

      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      print('[ApiService] Response status: ${response.statusCode}');
      print('[ApiService] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Access denied');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Upload failed');
      }
    } catch (e) {
      print('[ApiService] Upload error: $e');
      rethrow;
    }
  }

  // Generic GET request helper
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      print('[ApiService] GET from: $_baseUrl$endpoint');

      final token = await _getAuthToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('[ApiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      print('[ApiService] Error: $e');
      rethrow;
    }
  }

  // Generic streaming endpoint
  Stream<String> postStream(
    String endpoint,
    Map<String, dynamic> body,
  ) async* {
    try {
      print('[ApiService] POST Stream to: $_baseUrl$endpoint');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final request = http.Request('POST', Uri.parse('$_baseUrl$endpoint'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.body = jsonEncode(body);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        throw Exception('Stream failed with status ${streamedResponse.statusCode}');
      }

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    } catch (e) {
      print('[ApiService] Stream error: $e');
      rethrow;
    }
  }

  // ===================================================================
  // ================ EXISTING METHODS (PRESERVED) =====================
  // ===================================================================

  Future<Map<String, dynamic>> analyzeProductImage(File imageFile) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('User is not logged in. Cannot perform scan.');
    }

    final String analyzeEndpoint = "$_baseUrl/api/analyze-product";
    var request = http.MultipartRequest('POST', Uri.parse(analyzeEndpoint));
    request.headers['Authorization'] = 'Bearer $token';

    String? contentTypeString = mime(imageFile.path);
    MediaType? mediaType;
    if (contentTypeString != null) {
      var parts = contentTypeString.split('/');
      if (parts.length == 2) mediaType = MediaType(parts[0], parts[1]);
    }

    request.files.add(
      await http.MultipartFile.fromPath('productImage', imageFile.path, contentType: mediaType),
    );

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['error'] ?? 'Failed to analyze product.';
        if (errorData['limitReached'] == true) {
          throw Exception('LIMIT_REACHED: $errorMessage');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> analyzeDocumentMultipart({
    required File documentFile,
    required String documentType,
    String? question,
  }) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('User is not logged in. Cannot analyze document.');
    }

    final String analyzeEndpoint = "$_baseUrl/api/analyze-document";
    var request = http.MultipartRequest('POST', Uri.parse(analyzeEndpoint));
    request.headers['Authorization'] = 'Bearer $token';

    String? contentTypeString = mime(documentFile.path);
    MediaType? mediaType;
    if (contentTypeString != null) {
      var parts = contentTypeString.split('/');
      if (parts.length == 2) {
        mediaType = MediaType(parts[0], parts[1]);
      }
    }

    // If no MIME type detected, infer from file extension
    if (mediaType == null) {
      if (documentFile.path.toLowerCase().endsWith('.pdf')) {
        mediaType = MediaType('application', 'pdf');
      } else if (documentFile.path.toLowerCase().endsWith('.jpg') || 
                 documentFile.path.toLowerCase().endsWith('.jpeg')) {
        mediaType = MediaType('image', 'jpeg');
      } else if (documentFile.path.toLowerCase().endsWith('.png')) {
        mediaType = MediaType('image', 'png');
      }
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        documentFile.path,
        contentType: mediaType,
      ),
    );

    // Add form fields
    request.fields['documentType'] = documentType;
    if (question != null && question.isNotEmpty) {
      request.fields['question'] = question;
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['error'] ?? 'Failed to analyze document.';
        if (errorData['limitReached'] == true) {
          throw Exception('LIMIT_REACHED: $errorMessage');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// NEW: Analyze document by sending URL (uploaded by client)
  Future<Map<String, dynamic>> analyzeDocumentWithUrl({
    required String documentUrl,
    required String documentType,
    String? question,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('User is not logged in. Cannot analyze document.');
    }

    final String analyzeEndpoint = "$_baseUrl/api/analyze-document";
    final body = {
      'documentUrl': documentUrl,
      'documentType': documentType,
    };
    if (question != null && question.isNotEmpty) {
      body['question'] = question;
    }

    final response = await http.post(
      Uri.parse(analyzeEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Access denied');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to analyze document.');
    }
  }

  Future<Map<String, dynamic>> getAppConfig() async {
    final url = Uri.parse('$_baseUrl/api/config');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'freeScanLimit': 4};
      }
    } catch (e) {
      return {'freeScanLimit': 4};
    }
  }

  Future<Guide> fetchAiPoweredGuideContent({
    required String topic,
    required String languageCode,
    required UserProfile userProfile,
  }) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('User not authenticated.');

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    final userContext = {
      'trimester': userProfile.selectedTrimester,
      'allergies': userProfile.knownAllergies,
      'dietaryPreference': userProfile.dietaryPreference,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/generate-guide'),
      headers: headers,
      body: jsonEncode({
        'topic': topic,
        'languageCode': languageCode,
        'userContext': userContext,
      }),
    );

    if (response.statusCode == 200) {
      return Guide.fromMap(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      final errorData = json.decode(response.body);
      String errorMessage = errorData['error'] ?? 'Failed to generate AI guide.';
      if (errorData['limitReached'] == true) {
        throw Exception('LIMIT_REACHED: $errorMessage');
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> askExpert({
    required String question,
    required UserProfile userProfile,
  }) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('User not authenticated.');

    final userContext = {
      'trimester': userProfile.selectedTrimester,
      'allergies': userProfile.knownAllergies,
      'dietaryPreference': userProfile.dietaryPreference,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/ask-expert'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'question': question,
        'userContext': userContext,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final errorData = json.decode(response.body);
      String errorMessage = errorData['error'] ?? 'Failed to get answer.';
      if (errorData['limitReached'] == true) {
        throw Exception('LIMIT_REACHED: $errorMessage');
      }
      throw Exception(errorMessage);
    }
  }

  Future<List<Map<String, dynamic>>> premiumProductSearch(
    String searchQuery,
    Map<String, dynamic> userContext
  ) async {
    const String functionName = 'premium-product-search';
    print("[ApiService] Calling Supabase Function (AI Proxy): $functionName with query: '$searchQuery' and context: $userContext");

    try {
      final String? accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
      if (accessToken == null) {
        print("[ApiService] No access token for premium search.");
        throw Exception("User not authenticated.");
      }

      final response = await Supabase.instance.client.functions.invoke(
        functionName,
        method: HttpMethod.post,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: {
          'query': searchQuery,
          'userContext': userContext,
        },
      );

      print("[ApiService] AI Search via Edge Function - Status: ${response.status}");

      if (response.status != null && response.status >= 200 && response.status < 300) {
        if (response.data == null) {
           print("[ApiService] AI Search - Supabase Function returned successful status but no data.");
           return [];
        }
        if (response.data is List) {
          final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(
            (response.data as List).map((item) {
              if (item is Map<String, dynamic>) {
                return item;
              } else if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              print("[ApiService] Warning: Unexpected item type in AI search results: ${item.runtimeType}");
              return <String, dynamic>{};
            }).where((item) => item.isNotEmpty)
          );
          print("[ApiService] AI Premium search successful. Received ${results.length} analysis object(s).");
          return results;
        } else {
           print("[ApiService] AI Search - Unexpected data format from Edge Function: ${response.data.runtimeType}. Data: ${response.data}");
           throw Exception("AI search returned an unexpected data format.");
        }
      } else {
        String errorMessage = "AI Premium search failed.";
        if (response.data != null) {
            if (response.data is Map && response.data['error'] != null) {
                errorMessage = response.data['error'] is String ? response.data['error'] : json.encode(response.data['error']);
            } else if (response.data is Map && response.data['message'] != null) {
                errorMessage = response.data['message'] is String ? response.data['message'] : json.encode(response.data['message']);
            } else if (response.data is String && (response.data as String).isNotEmpty) {
                errorMessage = response.data as String;
            } else {
                errorMessage += " Status: ${response.status}. Details: ${response.data.toString()}";
            }
        } else if (response.status != null) {
          errorMessage += " Status: ${response.status}";
        }
        print("[ApiService] Error in AI premium search: $errorMessage. Data: ${response.data}");
        throw Exception(errorMessage);
      }
    } on FunctionException catch (e,s) {
      print("[ApiService] Supabase FunctionException (AI Search): Status: ${e.status}, Details: ${e.details}, FullError: ${e.toString()} \nStack: $s");
      String userMessage = "AI search request failed (Code: ${e.status}).";

      if (e.status == 401 || e.status == 403) {
        userMessage = "Access denied. Premium membership may be required or your session has expired.";
      } else if (e.details != null) {
        if (e.details is String && (e.details as String).isNotEmpty) {
          userMessage = e.details as String;
        } else if (e.details is Map) {
          final Map<String, dynamic> detailsMap = Map<String, dynamic>.from(e.details as Map);
          if (detailsMap['error'] is String && (detailsMap['error'] as String).isNotEmpty) {
            userMessage = detailsMap['error'] as String;
          } else if (detailsMap['message'] is String && (detailsMap['message'] as String).isNotEmpty) {
            userMessage = detailsMap['message'] as String;
          } else if (detailsMap.isNotEmpty) {
             userMessage = "AI search error: ${detailsMap.toString()} (Code: ${e.status})";
          }
        } else if (e.details.toString().isNotEmpty) {
            userMessage = e.details.toString();
        }
      } else {
        userMessage = "AI Function error (Status: ${e.status}). ${e.toString()}";
      }
      throw Exception(userMessage);
    } on SocketException catch (e, s) {
      print("[ApiService] Network error during AI premium search (Supabase Function): $e\n$s");
      throw Exception("Network error: Please check your internet connection.");
    } catch (e, s) {
      print("[ApiService] Unexpected error during AI premium search: $e\n$s");
      throw Exception("An unexpected error occurred during AI premium search.");
    }
  }
  
  Future<Map<String, dynamic>> createDodoCheckoutSession({required String planType}) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }
    
    final body = jsonEncode({
      'planType': planType,
    });

    print("[ApiService] Creating Dodo Checkout for plan: $planType");

    final response = await http.post(
      Uri.parse('$_baseUrl/api/payments/create-dodo-checkout'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to create checkout session.');
    }
  }

  // ===================================================================
  // ================ STREAMING METHODS (PRESERVED) ====================
  // ===================================================================

  Stream<String> askExpertStream({
    required String question,
    required UserProfile userProfile,
  }) async* {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final userContext = {
      'trimester': userProfile.selectedTrimester,
      'allergies': userProfile.knownAllergies,
      'dietaryPreference': userProfile.dietaryPreference,
    };

    final request = http.Request('POST', Uri.parse('$_baseUrl/api/ask-expert'))
      ..headers.addAll({
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode({
        'question': question,
        'userContext': userContext,
      });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        final errorData = json.decode(body);
        String errorMessage = errorData['error'] ?? 'Failed to get answer.';
        if (errorData['limitReached'] == true) {
          throw Exception('LIMIT_REACHED: $errorMessage');
        }
        throw Exception(errorMessage);
      }
      
      // Regular expression to find the JSON part of the SSE data events
      final sseRegex = RegExp(r'^data: (.*)');

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;
        
        final match = sseRegex.firstMatch(chunk);
        if (match != null) {
            final jsonData = match.group(1)!;
            try {
                final decodedData = json.decode(jsonData);
                if (decodedData['text'] != null) {
                    yield decodedData['text'];
                }
            } catch (e) {
                print("Error parsing SSE chunk: $e");
            }
        }
      }
    } finally {
      client.close();
    }
  }

  Stream<String> generateGuideStream({
    required String topic,
    required String languageCode,
    required UserProfile userProfile,
  }) async* {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final userContext = {
      'trimester': userProfile.selectedTrimester,
      'allergies': userProfile.knownAllergies,
      'dietaryPreference': userProfile.dietaryPreference,
    };

    final request = http.Request('POST', Uri.parse('$_baseUrl/api/generate-guide'))
      ..headers.addAll({
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode({
        'topic': topic,
        'languageCode': languageCode,
        'userContext': userContext,
      });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        final errorData = json.decode(body);
        String errorMessage = errorData['error'] ?? 'Failed to generate AI guide.';
        if (errorData['limitReached'] == true) {
          throw Exception('LIMIT_REACHED: $errorMessage');
        }
        throw Exception(errorMessage);
      }
      
      final sseRegex = RegExp(r'^data: (.*)');

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;
        
        final match = sseRegex.firstMatch(chunk);
        if (match != null) {
            final jsonData = match.group(1)!;
            try {
                final decodedData = json.decode(jsonData);
                if (decodedData['text'] != null) {
                    yield decodedData['text'];
                }
            } catch (e) {
                print("Error parsing SSE chunk: $e");
            }
        }
      }
    } finally {
      client.close();
    }
  }

  // Document Analysis Stream (similar to askExpertStream)
  Stream<String> documentAnalysisStream(Map<String, dynamic> body) {
    return postStream('/api/analyze-document-stream', body);
  }

  // ===================================================================
  // ================ PREGNANCY TOOLS STREAMING METHODS ================
  // ===================================================================

  /// Generic streaming method for pregnancy tools AI endpoints
  Stream<String> pregnancyToolsAIStream({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async* {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final fullUrl = '$_baseUrl$endpoint';
    print('[ApiService] Starting stream to: $fullUrl');
    print('[ApiService] Request body: ${jsonEncode(body)}');

    final request = http.Request('POST', Uri.parse(fullUrl))
      ..headers.addAll({
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode(body);

    final client = http.Client();
    try {
      print('[ApiService] Sending request...');
      final response = await client.send(request).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timed out after 60 seconds');
        },
      );

      print('[ApiService] Response received. Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final bodyText = await response.stream.bytesToString();
        print('[ApiService] Error response body: $bodyText');
        try {
          final errorData = json.decode(bodyText);
          String errorMessage = errorData['error'] ?? 'Failed to get AI analysis.';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to get AI analysis. Status: ${response.statusCode}, Body: $bodyText');
        }
      }
      
      // Parse SSE format: "data: {json}\n\n"
      final sseRegex = RegExp(r'^data: (.*)');
      print('[ApiService] Starting to read stream...');

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;
        
        final match = sseRegex.firstMatch(chunk);
        if (match != null) {
          final jsonData = match.group(1)!;
          try {
            final decodedData = json.decode(jsonData);
            if (decodedData['text'] != null) {
              yield decodedData['text'];
            } else if (decodedData['done'] == true) {
              print('[ApiService] Stream completed successfully');
              break;
            }
          } catch (e) {
            print('[ApiService] Error parsing SSE chunk: $e');
          }
        }
      }
    } catch (e) {
      print('[ApiService] Stream error: $e');
      rethrow;
    } finally {
      client.close();
      print('[ApiService] Client closed');
    }
  }

  // Birth Plan AI - Streaming
  Stream<String> birthPlanAIStream(Map<String, dynamic> birthPlanData) {
    return pregnancyToolsAIStream(
      endpoint: '/api/pregnancy-tools/birth-plan-ai-stream',
      body: {'birthPlanData': birthPlanData},
    );
  }

  // Postpartum Tracker AI - Streaming
  Stream<String> postpartumTrackerAIStream({
    required String symptoms,
    required int daysPostpartum,
  }) {
    return pregnancyToolsAIStream(
      endpoint: '/api/pregnancy-tools/postpartum-tracker-ai-stream',
      body: {
        'symptoms': symptoms,
        'daysPostpartum': daysPostpartum,
      },
    );
  }

  // Vaccine Tracker AI - Streaming
  Stream<String> vaccineTrackerAIStream({
    required int babyAgeMonths,
    required List<String> completedVaccines,
  }) {
    return pregnancyToolsAIStream(
      endpoint: '/api/pregnancy-tools/vaccine-tracker-ai-stream',
      body: {
        'babyAgeMonths': babyAgeMonths,
        'completedVaccines': completedVaccines,
      },
    );
  }

  // Weight Gain Tracker AI - Streaming
  Stream<String> weightGainTrackerAIStream({
    required double currentWeight,
    required double prePregnancyWeight,
    required int currentWeek,
    required double height,
    required String bmi,
  }) {
    return pregnancyToolsAIStream(
      endpoint: '/api/pregnancy-tools/weight-gain-ai-stream',
      body: {
        'currentWeight': currentWeight,
        'prePregnancyWeight': prePregnancyWeight,
        'currentWeek': currentWeek,
        'height': height,
        'bmi': bmi,
      },
    );
  }

  // Hospital Bag Checklist AI - Streaming
  Stream<String> hospitalBagAIStream({
    required List<String> packedItems,
    required List<String> missingItems,
  }) {
    return pregnancyToolsAIStream(
      endpoint: '/api/pregnancy-tools/hospital-bag-ai-stream',
      body: {
        'packedItems': packedItems,
        'missingItems': missingItems,
      },
    );
  }

  // Contraction Timer Analysis - Streaming
  Stream<String> contractionAnalyzeStream(List<Map<String, dynamic>> contractions) {
    return pregnancyToolsAIStream(
      endpoint: '/api/pregnancy-tools/contraction-analyze-stream',
      body: {'contractions': contractions},
    );
  }
}
