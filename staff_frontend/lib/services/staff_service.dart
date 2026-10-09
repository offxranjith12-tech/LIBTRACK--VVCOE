import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class StaffService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /api/staff/me — Dashboard profile card + Profile screen.
  Future<Staff> getProfile() async {
    try {
      final res = await _dio.get('/staff/me');
      return Staff.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// PUT /api/staff/me — Profile screen's "Edit Profile".
  Future<Staff> updateProfile(Staff staff) async {
    try {
      final res = await _dio.put('/staff/me', data: staff.toJson());
      return Staff.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
