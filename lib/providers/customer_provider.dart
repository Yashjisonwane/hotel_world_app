import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class CustomerProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Customer> _customers = [];
  bool _isLoading = false;

  CustomerProvider(this._apiService) {
    _loadFromCache();
  }

  void _loadFromCache() {
    try {
      final raw = StorageService.getString(StorageService.cacheCustomersKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        _customers = list.map((c) => Customer.fromJson(Map<String, dynamic>.from(c))).toList();
      }
    } catch (_) {}
  }

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  void _syncCache() {
    StorageService.setString(
      StorageService.cacheCustomersKey,
      jsonEncode(_customers.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> fetchCustomers({String? query}) async {
    if (_customers.isEmpty || (query != null && query.isNotEmpty)) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final fresh = await _apiService.getCustomers(search: query);
      _customers = fresh;
      if (query == null || query.isEmpty) {
        _syncCache();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<Customer?> addCustomer(Map<String, dynamic> data) async {
    try {
      final cust = await _apiService.createCustomer(data);
      _customers.insert(0, cust);
      _syncCache();
      notifyListeners();
      return cust;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _apiService.updateCustomer(id, data);
      final idx = _customers.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _customers[idx] = updated;
        _syncCache();
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _apiService.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      _syncCache();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
