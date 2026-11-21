import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/quotation.dart';
import '../models/customer.dart';
import '../models/company_settings.dart';
import 'storage_service.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _initDio();
  }

  void _initDio() {
    final baseUrl = StorageService.getBackendUrl();
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.getBaseApi(baseUrl),
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final user = StorageService.getCurrentUser();
          if (user != null) {
            options.headers['x-requester-role'] = user.role;
            options.headers['x-requester-email'] = user.email;
            options.headers['x-requester-id'] = user.id;
          }
          final token = StorageService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await StorageService.clearSession();
          }
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    _initDio();
  }

  String get currentBackendUrl => StorageService.getBackendUrl();

  // ---------------- AUTH ----------------
  Future<User> login(String email, String password) async {
    try {
      final res = await _dio.post(
        ApiConstants.login,
        data: {'email': email.trim(), 'password': password.trim()},
      );
      if (res.data != null && res.data['success'] == true) {
        final userData = res.data['user'];
        final user = User.fromJson(userData);
        await StorageService.setCurrentUser(user);
        if (res.data['token'] != null) {
          await StorageService.setAuthToken(res.data['token'].toString());
        }
        return user;
      }
      throw Exception(res.data?['error'] ?? 'Login failed');
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data?['error'] ?? e.message;
        throw Exception(msg);
      }
      rethrow;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final res = await _dio.get(ApiConstants.users);
      if (res.data != null && res.data['users'] is List) {
        return (res.data['users'] as List).map((u) => User.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.users, data: data);
    if (res.data['success'] == true) {
      return User.fromJson(res.data['user']);
    }
    throw Exception(res.data['error'] ?? 'Failed to create user');
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.users}/$id', data: data);
    if (res.data['success'] != true) {
      throw Exception(res.data['error'] ?? 'Failed to update user');
    }
  }

  Future<void> deleteUser(String id) async {
    final res = await _dio.delete('${ApiConstants.users}/$id');
    if (res.data['success'] != true) {
      throw Exception(res.data['error'] ?? 'Failed to delete user');
    }
  }

  Future<String?> uploadAvatar(File imageFile) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(imageFile.path),
    });
    final res = await _dio.post(ApiConstants.uploadAvatar, data: formData);
    if (res.data['success'] == true) {
      return res.data['avatarUrl'] ?? res.data['avatar'];
    }
    return null;
  }

  // ---------------- PRODUCTS ----------------
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 30,
    String? search,
    String? category,
    String? sourceFile,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
      if (category != null && category.isNotEmpty && category != 'ALL') query['category'] = category;
      if (sourceFile != null && sourceFile.isNotEmpty && sourceFile != 'ALL') query['sourceFile'] = sourceFile;

      final res = await _dio.get(ApiConstants.products, queryParameters: query);
      if (res.data != null && res.data['products'] is List) {
        final products = (res.data['products'] as List).map((p) => Product.fromJson(p)).toList();
        return {
          'products': products,
          'total': res.data['total'] ?? products.length,
          'totalPages': res.data['totalPages'] ?? 1,
        };
      }
      return {'products': <Product>[], 'total': 0, 'totalPages': 1};
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  /// Hybrid AI Semantic Search for Indian kitchen equipment
  Future<Map<String, dynamic>> searchProductsAi(String query, {int limit = 30}) async {
    try {
      final res = await _dio.get(
        ApiConstants.productSearch,
        queryParameters: {'q': query.trim(), 'limit': limit},
      );
      if (res.data != null && res.data['success'] == true) {
        final List rawResults = res.data['results'] is List ? res.data['results'] : [];
        final products = rawResults.map((p) => Product.fromJson(p)).toList();

        final List rawSugg = res.data['aiSuggestions'] is List ? res.data['aiSuggestions'] : [];
        final suggestions = rawSugg
            .map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty && !RegExp(r'^\d+$').hasMatch(s))
            .toList();

        final interpretation = res.data['aiInterpretation']?.toString();

        return {
          'products': products,
          'aiSuggestions': suggestions,
          'aiInterpretation': interpretation,
        };
      }
      return {'products': <Product>[], 'aiSuggestions': <String>[], 'aiInterpretation': null};
    } catch (e) {
      return {'products': <Product>[], 'aiSuggestions': <String>[], 'aiInterpretation': null};
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final res = await _dio.get(ApiConstants.productCategories);
      if (res.data != null && res.data['categories'] is List) {
        return List<String>.from(res.data['categories']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.products, data: data);
    if (res.data['success'] == true) {
      return Product.fromJson(res.data['product']);
    }
    throw Exception(res.data['error'] ?? 'Failed to create product');
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.products}/$id', data: data);
    if (res.data['success'] == true) {
      return Product.fromJson(res.data['product']);
    }
    throw Exception(res.data['error'] ?? 'Failed to update product');
  }

  Future<void> deleteProduct(int id) async {
    final res = await _dio.delete('${ApiConstants.products}/$id');
    if (res.data['success'] != true) {
      throw Exception(res.data['error'] ?? 'Failed to delete product');
    }
  }

  Future<String?> uploadProductPhoto(File file, {int? productId}) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path),
    });
    final path = productId != null ? '${ApiConstants.products}/$productId/upload-photo' : ApiConstants.uploadProductPhoto;
    final res = await _dio.post(path, data: formData);
    if (res.data['success'] == true) {
      return res.data['imageUrl'] ?? res.data['url'];
    }
    return null;
  }

  // ---------------- QUOTATIONS ----------------
  Future<Map<String, dynamic>> getQuotations({
    int page = 1,
    int limit = 30,
    String? search,
    String? status,
  }) async {
    try {
      final user = StorageService.getCurrentUser();
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) query['q'] = search.trim();
      if (status != null && status.isNotEmpty && status != 'ALL') query['status'] = status;
      if (user != null) {
        query['role'] = user.role;
        query['userId'] = user.id;
        query['userEmail'] = user.email;
        query['canViewAll'] = user.canViewPreviousQuotations.toString();
      }

      final res = await _dio.get(ApiConstants.quotations, queryParameters: query);
      if (res.data != null && res.data['quotations'] is List) {
        final quotes = (res.data['quotations'] as List).map((q) => Quotation.fromJson(q)).toList();
        return {
          'quotations': quotes,
          'total': res.data['total'] ?? quotes.length,
          'totalPages': res.data['totalPages'] ?? 1,
        };
      }
      return {'quotations': <Quotation>[], 'total': 0, 'totalPages': 1};
    } catch (e) {
      throw Exception('Failed to load quotations: $e');
    }
  }

  Future<Quotation> getQuotationById(String id) async {
    final res = await _dio.get('${ApiConstants.quotations}/$id');
    if (res.data != null && res.data['quotation'] != null) {
      return Quotation.fromJson(res.data['quotation']);
    }
    throw Exception('Quotation not found');
  }

  Future<Quotation> saveQuotation(Map<String, dynamic> data) async {
    final user = StorageService.getCurrentUser();
    if (user != null) {
      data['createdById'] ??= user.id;
      data['createdByEmail'] ??= user.email;
      data['preparedBy'] ??= user.name;
    }
    final res = await _dio.post(ApiConstants.quotations, data: data);
    if (res.data['success'] == true && res.data['quotation'] != null) {
      return Quotation.fromJson(res.data['quotation']);
    }
    throw Exception(res.data['error'] ?? 'Failed to save quotation');
  }

  Future<void> deleteQuotation(String id) async {
    final res = await _dio.delete('${ApiConstants.quotations}/$id');
    if (res.data['success'] != true) {
      throw Exception(res.data['error'] ?? 'Failed to delete quotation');
    }
  }

  // ---------------- CUSTOMERS ----------------
  Future<List<Customer>> getCustomers({String? search}) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) query['q'] = search.trim();
      final res = await _dio.get(ApiConstants.customers, queryParameters: query);
      if (res.data != null && res.data['customers'] is List) {
        return (res.data['customers'] as List).map((c) => Customer.fromJson(c)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.customers, data: data);
    if (res.data['success'] == true) {
      return Customer.fromJson(res.data['customer']);
    }
    throw Exception(res.data['error'] ?? 'Failed to create customer');
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.customers}/$id', data: data);
    if (res.data['success'] == true) {
      return Customer.fromJson(res.data['customer']);
    }
    throw Exception(res.data['error'] ?? 'Failed to update customer');
  }

  Future<void> deleteCustomer(String id) async {
    final res = await _dio.delete('${ApiConstants.customers}/$id');
    if (res.data['success'] != true) {
      throw Exception(res.data['error'] ?? 'Failed to delete customer');
    }
  }

  // ---------------- SETTINGS ----------------
  Future<CompanySettings> getSettings() async {
    try {
      final res = await _dio.get(ApiConstants.settings);
      if (res.data != null && res.data['settings'] != null) {
        return CompanySettings.fromJson(res.data['settings']);
      }
      return CompanySettings();
    } catch (_) {
      return CompanySettings();
    }
  }

  Future<CompanySettings> updateSettings(Map<String, dynamic> data) async {
    final res = await _dio.put(ApiConstants.settings, data: data);
    if (res.data['success'] == true && res.data['settings'] != null) {
      return CompanySettings.fromJson(res.data['settings']);
    }
    throw Exception(res.data['error'] ?? 'Failed to update settings');
  }

  Future<String?> uploadLogo(File file) async {
    final formData = FormData.fromMap({
      'logo': await MultipartFile.fromFile(file.path),
    });
    final res = await _dio.post(ApiConstants.uploadLogo, data: formData);
    if (res.data['success'] == true) {
      return res.data['logoUrl'] ?? res.data['url'];
    }
    return null;
  }
}

