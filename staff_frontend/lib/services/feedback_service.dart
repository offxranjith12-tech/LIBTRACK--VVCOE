import 'package:dio/dio.dart';
import 'api_client.dart';

class FeedbackEntry {
  final String id;
  final String message;
  final int? rating;
  final DateTime submittedAt;

  const FeedbackEntry({required this.id, required this.message, this.rating, required this.submittedAt});

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
        id: '${json['id']}',
        message: json['message'] ?? '',
        rating: json['rating'],
        submittedAt: DateTime.parse(json['submittedAt']),
      );
}

class FeedbackService {
  final Dio _dio = ApiClient.instance.dio;

  /// POST /api/feedback — the Feedback screen's submit form.
  Future<FeedbackEntry> submit(String message, int? rating) async {
    try {
      final res = await _dio.post('/feedback', data: {
        'message': message,
        if (rating != null) 'rating': rating,
      });
      return FeedbackEntry.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /api/feedback — the Feedback screen's history list.
  Future<List<FeedbackEntry>> getAll() async {
    try {
      final res = await _dio.get('/feedback');
      return (res.data as List).map((e) => FeedbackEntry.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
