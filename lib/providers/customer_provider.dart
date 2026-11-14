import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

class CustomerProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Customer> _customers = [];
  bool _isLoading = false;

  CustomerProvider(this._apiService);

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> fetchCustomers({String? query}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _apiService.getCustomers(search: query);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<Customer?> addCustomer(Map<String, dynamic> data) async {
    try {
      final cust = await _apiService.createCustomer(data);
      _customers.insert(0, cust);
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
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
