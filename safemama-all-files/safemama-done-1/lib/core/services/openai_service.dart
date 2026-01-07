import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey = 'your-api-key-here'; // Replace with your actual API key

  static OpenAIService? _instance;
  OpenAIService._();

  // Factory constructor to return singleton
  factory OpenAIService() {
    return _instance ??= OpenAIService._();
  }

  Future<String> generateCompletion(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to generate completion');
      }
    } catch (e) {
      throw Exception('OpenAI API Error: $e');
    }
  }

  Future<String> analyzeImageWithGPT4Vision(String imagePath, String prompt) async {
    try {
      // For now, return a placeholder response
      // You can implement actual GPT-4 Vision API call here
      return "Image analysis completed successfully. The document appears to contain relevant pregnancy-related information.";
    } catch (e) {
      throw Exception('Image analysis failed: $e');
    }
  }
}
