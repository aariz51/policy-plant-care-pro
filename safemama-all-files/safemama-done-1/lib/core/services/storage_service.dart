import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Factory constructor to return singleton
  factory StorageService() {
    return _instance ?? StorageService._();
  }

  Future<String?> getString(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString(key);
  }

  Future<bool> setString(String key, String value) async {
    _prefs ??= await SharedPreferences.getInstance();
    return await _prefs!.setString(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getStringList(key);
  }

  Future<bool> remove(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return await _prefs!.remove(key);
  }
}
