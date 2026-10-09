import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  /// POST /api/auth/login → stores the JWT and returns the staff profile.
  Future<Staff> login(String username, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final token = res.data['token'] as String;
      await ApiClient.instance.saveToken(token);
      return Staff.fromJson(res.data['staff']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() => ApiClient.instance.clearToken();

  Future<bool> get isLoggedIn => ApiClient.instance.isLoggedIn;

  /// PUT /api/auth/change-password — Profile screen's "Change Password".
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dio.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
