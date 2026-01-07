class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();
  
  // Base URL for your API
  static const String baseUrl = 'http://192.168.29.229:3001'; // Replace with your actual API domain
  
  // Specific endpoints
  static const String analyzeProductEndpoint = '$baseUrl/api/analyze-product';
  static const String generateBabyNamesEndpoint = '$baseUrl/api/generate-baby-names';
  static const String askExpertEndpoint = '$baseUrl/api/ask-expert';
  static const String generateGuideEndpoint = '$baseUrl/api/generate-guide';
  static const String paymentEndpoint = '$baseUrl/api/payments';
  
  // API Keys (if needed)
  static const String openaiApiKey = 'REMOVED_SECRET_KEY'; // Replace with actual key
  
  // API Version
  static const String apiVersion = 'v1';
  
  // Timeout configurations
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 2);
}
