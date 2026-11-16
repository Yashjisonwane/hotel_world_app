import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/company_settings.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiService _apiService;
  CompanySettings _settings = CompanySettings();
  bool _isLoading = false;
  String _backendUrl = '';

  SettingsProvider(this._apiService) {
    _backendUrl = StorageService.getBackendUrl();
    _loadFromCache();
    loadSettings();
  }

  void _loadFromCache() {
    try {
      final raw = StorageService.getString(StorageService.cacheSettingsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) {
          _settings = CompanySettings.fromJson(map);
        }
      }
    } catch (_) {}
  }

  CompanySettings get settings => _settings;
  bool get isLoading => _isLoading;
  String get backendUrl => _backendUrl;

  Future<void> loadSettings() async {
    try {
      final fresh = await _apiService.getSettings();
      _settings = fresh;
      StorageService.setString(StorageService.cacheSettingsKey, jsonEncode(fresh.toJson()));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateBackendUrl(String newUrl) async {
    final clean = newUrl.trim();
    if (clean.isEmpty) return;
    await StorageService.setBackendUrl(clean);
    _backendUrl = clean;
    _apiService.updateBaseUrl(clean);
    await loadSettings();
    notifyListeners();
  }

  Future<bool> saveSettings(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _apiService.updateSettings(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

