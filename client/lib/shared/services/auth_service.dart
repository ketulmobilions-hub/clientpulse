import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => 'AuthServiceException: $message';
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _userEmailKey = 'auth_user_email';
  static const _userNameKey = 'auth_user_name';
  static const _userRoleKey = 'auth_user_role';
  static const _userWorkspaceIdKey = 'auth_user_workspace_id';

  final SharedPreferences _prefs;
  final Dio _dio;

  AuthService({
    required SharedPreferences prefs,
    required String baseUrl,
    @visibleForTesting Dio? dio,
  })  : _prefs = prefs,
        _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  Future<AuthUser> login(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final body = response.data;
      if (body == null) throw AuthServiceException('Empty response from server');
      return await _handleAuthResponse(body);
    } on DioException catch (e) {
      throw AuthServiceException(_extractError(e));
    }
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String workspaceName,
  ) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'workspaceName': workspaceName,
        },
      );
    } on DioException catch (e) {
      throw AuthServiceException(_extractError(e));
    }
  }

  Future<void> logout() async {
    await Future.wait([
      _prefs.remove(_tokenKey),
      _prefs.remove(_userIdKey),
      _prefs.remove(_userEmailKey),
      _prefs.remove(_userNameKey),
      _prefs.remove(_userRoleKey),
      _prefs.remove(_userWorkspaceIdKey),
    ]);
  }

  String? getToken() => _prefs.getString(_tokenKey);

  /// Returns null if any required field is absent — prevents partial-session corruption.
  AuthUser? getUser() {
    final id = _prefs.getString(_userIdKey);
    final email = _prefs.getString(_userEmailKey);
    final name = _prefs.getString(_userNameKey);
    final role = _prefs.getString(_userRoleKey);
    final workspaceId = _prefs.getString(_userWorkspaceIdKey);
    if (id == null || email == null || name == null || role == null || workspaceId == null) {
      return null;
    }
    return AuthUser(
      id: id,
      email: email,
      name: name,
      role: role,
      workspaceId: workspaceId,
    );
  }

  /// Returns true if [token] has an `exp` claim in the past.
  /// Tokens without an `exp` claim are treated as non-expiring.
  // Buffer compensates for device clock running slightly behind the server clock.
  static const _clockSkewSeconds = 30;

  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp == null) return false;
      final expSeconds = (exp as num).toInt();
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSeconds + _clockSkewSeconds > expSeconds;
    } catch (_) {
      return true;
    }
  }

  Future<AuthUser> _handleAuthResponse(Map<String, dynamic> body) async {
    try {
      final data = body['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      await _saveSession(token, user);
      return user;
    } on TypeError catch (e) {
      throw AuthServiceException('Unexpected response format: $e');
    } on FormatException catch (e) {
      throw AuthServiceException('Unexpected response format: $e');
    }
  }

  // Known limitation: on Flutter Web, SharedPreferences maps to localStorage,
  // which is JS-readable. Tokens are therefore vulnerable to XSS. Mitigation:
  // enforce a strict Content-Security-Policy. Long-term fix: use HttpOnly cookies
  // issued by the backend instead.
  Future<void> _saveSession(String token, AuthUser user) async {
    await Future.wait([
      _prefs.setString(_tokenKey, token),
      _prefs.setString(_userIdKey, user.id),
      _prefs.setString(_userEmailKey, user.email),
      _prefs.setString(_userNameKey, user.name),
      _prefs.setString(_userRoleKey, user.role),
      _prefs.setString(_userWorkspaceIdKey, user.workspaceId),
    ]);
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return error['message']?.toString() ?? 'Unknown error';
      }
      if (error is String) return error;
    }
    return e.message ?? 'Network error';
  }
}
