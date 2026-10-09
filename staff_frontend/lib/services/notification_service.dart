import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class NotificationService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /api/notifications — Notifications screen.
  Future<List<LibNotification>> getAll() async {
    try {
      final res = await _dio.get('/notifications');
      return (res.data as List).map((e) => LibNotification.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/notifications/{id}/read — tapping a single notification card.
  Future<void> markRead(String id) async {
    try {
      await _dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/notifications/read-all — "Mark all read".
  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
