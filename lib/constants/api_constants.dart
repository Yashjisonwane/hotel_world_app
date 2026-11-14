/// Hotel World API Constants
/// Synchronized with backend on Render & local dev
class ApiConstants {
  // Live Render backend URL (Used by Web Application in production)
  static const String defaultLiveUrl = 'https://hotelworld-backend.onrender.com';
  
  // Storage key for custom / local backend override
  static const String prefBackendKey = 'hw_custom_backend_url';
  static const String prefAuthTokenKey = 'hw_auth_token';
  static const String prefUserDataKey = 'hw_user_data';

  // Base API path
  static String getBaseApi(String baseUrl) {
    final clean = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$clean/api';
  }

  // Endpoints
  static const String login = '/auth/login';
  static const String users = '/auth/users';
  static const String uploadAvatar = '/auth/profile/avatar';
  static const String changePassword = '/auth/change-password';

  static const String products = '/products';
  static const String productSearch = '/products/search';
  static const String productCategories = '/products/categories';
  static const String productSourceFiles = '/products/source-files';
  static const String productCount = '/products/count';
  static const String uploadProductPhoto = '/products/upload-photo';

  static const String quotations = '/quotations';
  static const String customers = '/customers';
  static const String settings = '/settings';
  static const String uploadLogo = '/settings/upload-logo';

  /// Resolves full image URL (handles Cloudinary, local server uploads, R2)
  static String resolveImageUrl(String? rawUrl, String backendUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final url = rawUrl.trim();
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) {
      return url;
    }
    final cleanBase = backendUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$cleanBase$cleanPath';
  }
}

