import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String getBackendUrl() {
    return _prefs?.getString(ApiConstants.prefBackendKey) ?? ApiConstants.defaultLiveUrl;
  }

  static Future<void> setBackendUrl(String url) async {
    await _prefs?.setString(ApiConstants.prefBackendKey, url.trim());
  }

  static String? getAuthToken() {
    return _prefs?.getString(ApiConstants.prefAuthTokenKey);
  }

  static Future<void> setAuthToken(String token) async {
    await _prefs?.setString(ApiConstants.prefAuthTokenKey, token);
  }

  static User? getCurrentUser() {
    final raw = _prefs?.getString(ApiConstants.prefUserDataKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      return User.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setCurrentUser(User user) async {
    await _prefs?.setString(ApiConstants.prefUserDataKey, jsonEncode(user.toJson()));
  }

  static Future<void> clearSession() async {
    await _prefs?.remove(ApiConstants.prefAuthTokenKey);
    await _prefs?.remove(ApiConstants.prefUserDataKey);
  }

  // Generic instant offline-first cache helpers
  static const String cacheQuotationsKey = 'hw_cache_quotations';
  static const String cacheProductsKey = 'hw_cache_products';
  static const String cacheCategoriesKey = 'hw_cache_categories';
  static const String cacheCustomersKey = 'hw_cache_customers';
  static const String cacheSettingsKey = 'hw_cache_settings';

  static String? getString(String key) => _prefs?.getString(key);
  static Future<void> setString(String key, String val) async => await _prefs?.setString(key, val);
}

