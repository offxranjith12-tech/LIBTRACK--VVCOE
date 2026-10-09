import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'api_client.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Talks to the real Spring Boot `/api/v1/auth` endpoints.
class AuthService {
  AuthService(this._client);
  final ApiClient _client;

  /// Logs in against the backend and stores the returned JWT.
  /// Throws [AuthException] with a user-facing message on failure —
  /// including when the backend simply isn't reachable, which is the
  /// most common issue during local development.
  Future<void> login({required String adminId, required String password}) async {
    try {
      final response = await _client.post('/auth/login', data: {
        'adminId': adminId,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw AuthException(data['message']?.toString() ?? 'Login failed');
      }

      final token = data['data']['token'] as String;
      await _client.saveToken(token);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        throw AuthException(
          'Could not reach the LibTrack server. Check that the backend is running '
          'and that AppConstants.baseUrl points to the right address.',
        );
      }
      final serverMessage = e.response?.data is Map ? e.response?.data['message'] : null;
      throw AuthException(serverMessage?.toString() ?? 'Invalid admin ID or password');
    }
  }

  Future<void> logout() => _client.clearToken();

  Future<bool> isLoggedIn() async {
    final token = await _client.readToken();
    if (token == null) return false;
    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }
}
