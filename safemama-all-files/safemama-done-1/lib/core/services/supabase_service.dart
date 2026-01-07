import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // If you're using .env for keys

class SupabaseService {
  // Private constructor
  SupabaseService._();

  // Singleton instance
  static final SupabaseService _instance = SupabaseService._();
  static SupabaseService get instance => _instance;

  SupabaseClient? _client;

  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
          "Supabase client not initialized. Call SupabaseService.initialize() first.");
    }
    return _client!;
  }

  static Future<void> initialize() async {
    if (_instance._client != null) {
      print("Supabase client already initialized.");
      return;
    }

    String supabaseUrl = '';
    String supabaseAnonKey = '';

    // Load from .env file
    // Ensure you have SUPABASE_URL and SUPABASE_ANON_KEY in your .env file
    try {
      // Attempt to load from dotenv if not already loaded.
      // Note: dotenv.load() might have already been called in main.dart.
      // This ensures keys are available if this method is called independently or for clarity.
      if (dotenv.env.isEmpty) {
        await dotenv.load(fileName: ".env");
      }
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        // If .env is not used or keys are missing, try using the hardcoded values from your prompt as a fallback.
        // THIS IS NOT RECOMMENDED FOR PRODUCTION. .env is preferred.
        print("Warning: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env file or are empty. Trying hardcoded values (NOT RECOMMENDED).");
        supabaseUrl = 'https://uzyvpbhzlyvvqurdyivq.supabase.co';
        supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6eXZwYmh6bHl2dnF1cmR5aXZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY1MDg0MTQsImV4cCI6MjA2MjA4NDQxNH0.NU0cyl8kB_xC2sXjZoh4te6rR2DExXMaxDj3OV7KKDQ';

        if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
             throw Exception(
            "Supabase URL or Anon Key is missing. Ensure they are in your .env file or provided directly.");
        }
      }
    } catch (e) {
      print("Error loading Supabase credentials: $e");
      // Fallback to hardcoded values if .env loading fails or keys are not there
      // THIS IS NOT RECOMMENDED FOR PRODUCTION. .env is preferred.
      print("Falling back to hardcoded Supabase credentials due to .env error (NOT RECOMMENDED).");
      supabaseUrl = 'https://uzyvpbhzlyvvqurdyivq.supabase.co';
      supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6eXZwYmh6bHl2dnF1cmR5aXZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY1MDg0MTQsImV4cCI6MjA2MjA4NDQxNH0.NU0cyl8kB_xC2sXjZoh4te6rR2DExXMaxDj3OV7KKDQ';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
           throw Exception(
          "Supabase URL or Anon Key is missing and fallback also failed.");
      }
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        // Optional: authCallbackUrlHostname: 'login-callback', // if you use deep links
        // Optional: debug: true, // Show Supabase logs in debug mode (set to kDebugMode for Flutter)
      );
      _instance._client = Supabase.instance.client;
      print(
          "supabase.supabase_flutter: INFO: ***** Supabase init completed (from SupabaseService) *****");
    } catch (e) {
      print("Error initializing Supabase: $e");
      rethrow; // Rethrow to halt app if Supabase can't init
    }
  }

  // Optional: Helper for easy access, though Supabase.instance.client is also global
  static SupabaseClient get clientInstance => _instance.client;

  // You can add other Supabase related utility functions here if needed
  // For example, a sign out method that also clears local user data
  Future<void> signOut() async {
    await client.auth.signOut();
    // Add any other local cleanup needed on sign out
  }
}
