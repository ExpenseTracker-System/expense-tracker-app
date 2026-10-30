import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  static const String _userCacheKey = 'cached_user_profile';

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get serverUrl => ApiService.instance.baseUrl;

  AuthProvider() {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    await ApiService.instance.initBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    final token = await ApiService.instance.getToken();
    final userJsonStr = prefs.getString(_userCacheKey);

    if (token != null && token.isNotEmpty && userJsonStr != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJsonStr) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> updateServerUrl(String newUrl) async {
    await ApiService.instance.setBaseUrl(newUrl);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 1. تسجيل الدخول بالبريد وكلمة المرور
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await ApiService.instance.post(
        '/api/auth/login',
        body: {'email': email.trim(), 'password': password},
        requiresAuth: false,
      );

      await _handleAuthSuccess(response);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  // 2. إنشاء حساب جديد
  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    try {
      final response = await ApiService.instance.post(
        '/api/auth/register',
        body: {
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        },
        requiresAuth: false,
      );

      await _handleAuthSuccess(response);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  // 3. تسجيل الدخول بواسطة حساب Google
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        _errorMessage = 'تم إلغاء تسجيل الدخول عبر جوجل';
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _errorMessage = 'تعذر الحصول على رمز التحقق من جوجل';
        _setLoading(false);
        return false;
      }

      final response = await ApiService.instance.post(
        '/api/auth/google',
        body: {'idToken': idToken},
        requiresAuth: false,
      );

      await _handleAuthSuccess(response);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'تعذر إتمام تسجيل الدخول عبر جوجل';
      _setLoading(false);
      return false;
    }
  }

  // 4. طلب رمز استعادة كلمة المرور (OTP)
  Future<bool> requestPasswordResetOtp(String email) async {
    _setLoading(true);
    try {
      final encodedEmail = Uri.encodeComponent(email.trim());
      await ApiService.instance.post(
        '/api/auth/forgot-password?email=$encodedEmail',
        requiresAuth: false,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  // 5. تأكيد الرمز وتعيين كلمة المرور الجديدة
  Future<bool> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await ApiService.instance.post(
        '/api/auth/reset-password',
        body: {
          'email': email.trim(),
          'otpCode': otpCode.trim(),
          'newPassword': newPassword,
        },
        requiresAuth: false,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  // 6. تسجيل الخروج (مع الحفاظ على البيانات المحلية على الهاتف)
  Future<void> logout() async {
    await ApiService.instance.clearToken();
    await SyncService.instance.clearSyncTimestamp();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> response) async {
    final data = response['data'] as Map<String, dynamic>;
    final String token = data['token'] as String;
    final userMap = data['userDto'] as Map<String, dynamic>;

    final user = UserModel.fromJson(userMap);
    await ApiService.instance.saveToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));

    // ربط المحافظ والمعاملات المحلية بحساب المستخدم لرفعها فور المزامنة
    await DatabaseHelper.instance.markAllDataForSync(user.id);

    _currentUser = user;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }
}