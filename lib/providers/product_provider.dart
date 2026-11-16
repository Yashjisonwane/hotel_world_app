import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  ProductProvider(this._apiService) {
    _loadFromCache();
    loadCategories();
    fetchProducts(refresh: true);
  }

  void _loadFromCache() {
    try {
      final rawCats = StorageService.getString(StorageService.cacheCategoriesKey);
      if (rawCats != null && rawCats.isNotEmpty) {
        final List cats = jsonDecode(rawCats);
        _categories = ['ALL', ...cats.map((e) => e.toString())];
      }
      final rawProds = StorageService.getString(StorageService.cacheProductsKey);
      if (rawProds != null && rawProds.isNotEmpty) {
        final List prods = jsonDecode(rawProds);
        _products = prods.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
        _totalCount = _products.length;
      }
    } catch (_) {}
  }

  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  int get totalCount => _totalCount;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> loadCategories() async {
    try {
      final cats = await _apiService.getCategories();
      _categories = ['ALL', ...cats];
      StorageService.setString(StorageService.cacheCategoriesKey, jsonEncode(cats));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    await fetchProducts(refresh: true);
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await fetchProducts(refresh: true);
  }

  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      if (_searchQuery.isNotEmpty) {
        _products = [];
      }
    }

    if (_products.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final res = await _apiService.getProducts(
        page: _currentPage,
        limit: 30,
        search: _searchQuery,
        category: _selectedCategory,
      );

      final List<Product> loaded = res['products'] as List<Product>;
      if (refresh) {
        _products = loaded;
        if (_searchQuery.isEmpty && _selectedCategory == 'ALL') {
          StorageService.setString(
            StorageService.cacheProductsKey,
            jsonEncode(_products.map((p) => p.toJson()).toList()),
          );
        }
      } else {
        _products.addAll(loaded);
      }
      _totalCount = res['total'] ?? _products.length;
      _totalPages = res['totalPages'] ?? 1;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoading || _currentPage >= _totalPages) return;
    _currentPage++;
    await fetchProducts(refresh: false);
  }

  void _syncCache() {
    if (_searchQuery.isEmpty && _selectedCategory == 'ALL') {
      StorageService.setString(
        StorageService.cacheProductsKey,
        jsonEncode(_products.map((p) => p.toJson()).toList()),
      );
    }
  }

  Future<bool> saveProduct({
    int? id,
    required String name,
    required String itemCode,
    required String category,
    required double sellingPrice,
    double? purchasePrice,
    double? mrp,
    String unit = 'Pcs',
    double taxRate = 18.0,
    String? description,
    File? photoFile,
  }) async {
    try {
      String? imageUrl;
      if (photoFile != null) {
        imageUrl = await _apiService.uploadProductPhoto(photoFile, productId: id);
      }

      final data = <String, dynamic>{
        'name': name,
        'itemCode': itemCode,
        'category': category,
        'sellingPrice': sellingPrice,
        if (purchasePrice != null) 'purchasePrice': purchasePrice,
        if (mrp != null) 'mrp': mrp,
        'unit': unit,
        'taxRate': taxRate,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      if (id != null && id > 0) {
        final updated = await _apiService.updateProduct(id, data);
        final idx = _products.indexWhere((p) => p.id == id);
        if (idx != -1) {
          _products[idx] = updated;
          _syncCache();
          notifyListeners();
        }
      } else {
        final created = await _apiService.createProduct(data);
        _products.insert(0, created);
        _totalCount++;
        _syncCache();
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _apiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _totalCount = (_totalCount > 0) ? _totalCount - 1 : 0;
      _syncCache();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

