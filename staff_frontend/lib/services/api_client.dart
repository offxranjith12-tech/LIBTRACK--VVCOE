import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central HTTP client for talking to the LibTrack Spring Boot backend.
///
/// - Change [baseUrl] to your server (use `10.0.2.2` instead of `localhost`
///   for the Android emulator; use your machine's LAN IP for a real device).
/// - The JWT returned by `/api/auth/login` is cached in secure storage and
///   attached to every subsequent request automatically.
/// - In debug builds, every request/response/error is printed to the
///   console (via [LogInterceptor]) so you can confirm the app is actually
///   reaching the backend — look for lines starting with "*** Request ***"
///   and "*** Response ***" / "*** DioException ***".
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Surface a consistent message shape; screens can read e.message.
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();

  /// Primary active IP address on Mobile Hotspot: 192.168.137.20
  /// Change to 'http://10.0.2.2:8080/api' if testing on Android Emulator
  /// Change to 'http://localhost:8080/api' if testing on Windows/Chrome
 static const String baseUrl = 'http://192.168.137.92:8080/api';


  static const _tokenKey = 'libtrack_jwt_token';
  final _storage = const FlutterSecureStorage();

  late final Dio _dio;
  Dio get dio => _dio;

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<bool> get isLoggedIn async => (await readToken()) != null;
}

/// Thrown by service methods to give screens a plain-English message,
/// unwrapped from Dio's exception shape.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(),
          statusCode: e.response?.statusCode);
    }
    return ApiException(e.message ?? 'Network error. Please try again.',
        statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}
