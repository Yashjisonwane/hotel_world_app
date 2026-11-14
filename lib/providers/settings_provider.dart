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
    loadSettings();
  }

  CompanySettings get settings => _settings;
  bool get isLoading => _isLoading;
  String get backendUrl => _backendUrl;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _apiService.getSettings();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
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

