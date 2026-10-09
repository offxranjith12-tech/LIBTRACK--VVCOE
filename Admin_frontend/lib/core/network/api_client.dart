import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Central Dio client wired to the Spring Boot backend.
/// Automatically attaches the JWT bearer token to every request and
/// handles 401s by clearing the session.
///
/// The backend base URL is **not** a hardcoded constant — on a real phone
/// `localhost` refers to the phone itself, not the developer's machine, so
/// every request would fail with a connection error (this is almost always
/// why "nothing works" the first time the app is installed on a device).
/// The URL is instead persisted via SharedPreferences and editable at
/// runtime from the Login screen's "Server Connection" sheet or from
/// Settings, so an admin can point the app at the right server without a
/// rebuild.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: AppConstants.tokenKey);
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _baseUrlPrefKey = 'server_base_url';

  Dio get dio => _dio;

  /// Call once at app startup (before runApp) to restore any previously
  /// saved server URL. Safe to call multiple times.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_baseUrlPrefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _dio.options.baseUrl = saved.trim();
      }
    } catch (_) {
      // Fall back silently to the compiled-in default if prefs are unavailable.
    }
  }

  /// The base URL currently in use, e.g. http://192.168.1.5:8080/api/v1
  String get baseUrl => _dio.options.baseUrl;

  /// The server's root (no /api/v1 suffix) — used to resolve relative
  /// resource paths returned by the backend, like avatar image URLs.
  String get fileServerRoot {
    final url = _dio.options.baseUrl;
    const suffix = '/api/v1';
    if (url.endsWith(suffix)) {
      return url.substring(0, url.length - suffix.length);
    }
    return url;
  }

  /// Resolves a relative path (e.g. "/uploads/avatars/x.jpg") returned by
  /// the backend into an absolute URL the app can load an image from.
  /// Returns null for empty input, and passes already-absolute URLs through.
  String? resolveFileUrl(String? relativeOrAbsolute) {
    if (relativeOrAbsolute == null || relativeOrAbsolute.trim().isEmpty) return null;
    final value = relativeOrAbsolute.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final root = fileServerRoot;
    return value.startsWith('/') ? '$root$value' : '$root/$value';
  }

  /// Persists a new base URL and applies it immediately to future requests.
  /// [url] should include the `/api/v1` suffix, e.g.
  /// `http://192.168.1.5:8080/api/v1`. Trailing slashes are trimmed.
  Future<void> setBaseUrl(String url) async {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) trimmed = trimmed.substring(0, trimmed.length - 1);
    if (trimmed.isEmpty) return;
    _dio.options.baseUrl = trimmed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_baseUrlPrefKey, trimmed);
    } catch (_) {
      // Non-fatal — the URL is still applied for this session even if it
      // couldn't be persisted.
    }
  }

  Future<void> resetBaseUrlToDefault() => setBaseUrl(AppConstants.baseUrl);

  /// Quick reachability check against the backend's public health endpoint
  /// (no auth required). Used by the "Test Connection" button.
  Future<bool> testConnection() async {
    try {
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      )).get('$fileServerRoot/actuator/health');
      return response.statusCode != null && response.statusCode! < 400;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveToken(String token) => _storage.write(key: AppConstants.tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: AppConstants.tokenKey);
  Future<void> clearToken() => _storage.delete(key: AppConstants.tokenKey);

  // --- Convenience wrappers -------------------------------------------------
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
