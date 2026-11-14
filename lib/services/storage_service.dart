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
}

