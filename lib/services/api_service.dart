import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// تعريف الأنواع لتجنب الأقواس المتداخلة وجعل الكود أنظف
typedef JsonMap = Map<String, dynamic>;
typedef HeadersMap = Map<String, String>;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_auth_token';
  static const String _baseUrlKey = 'server_base_url';

  // العنوان الافتراضي لمحاكي أندرويد (يمكن تغييره من إعدادات التطبيق للهاتف الحقيقي)
  String _baseUrl = 'https://mahfazati-backend.onrender.com';

  String get baseUrl => _baseUrl;

  Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_baseUrlKey)) {
      _baseUrl = prefs.getString(_baseUrlKey)!;
    }
  }

  Future<void> setBaseUrl(String newUrl) async {
    String cleaned = newUrl.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    _baseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  // ==================== إدارة التوكن المشفر ====================

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<HeadersMap> _getHeaders({bool requiresAuth = true}) async {
    final HeadersMap headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final String? token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ==================== دوال الطلبات العامة ====================

  Future<JsonMap> post(
    String endpoint, {
    JsonMap? body,
    bool requiresAuth = true,
  }) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl$endpoint');
      final HeadersMap headers = await _getHeaders(requiresAuth: requiresAuth);

      final http.Response response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('تعذر الاتصال بالخادم، تأكد من اتصالك بالإنترنت أو عنوان السيرفر');
    }
  }

  Future<JsonMap> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl$endpoint');
      final HeadersMap headers = await _getHeaders(requiresAuth: requiresAuth);

      final http.Response response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('تعذر الاتصال بالخادم، تأكد من اتصالك بالإنترنت');
    }
  }

  JsonMap _handleResponse(http.Response response) {
    final String decodedBody = utf8.decode(response.bodyBytes);
    JsonMap jsonMap = <String, dynamic>{};

    if (decodedBody.isNotEmpty) {
      jsonMap = jsonDecode(decodedBody) as JsonMap;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonMap;
    } else {
      final String errorMsg =
          jsonMap['message']?.toString() ?? 'حدث خطأ غير متوقع (${response.statusCode})';
      throw ApiException(errorMsg, statusCode: response.statusCode);
    }
  }
}