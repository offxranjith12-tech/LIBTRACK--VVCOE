import 'package:dio/dio.dart';
import 'api_client.dart';

class DashboardStats {
  final int borrowedBooks;
  final int returnedBooks;
  final int dueSoon;
  final int reservedBooks;

  const DashboardStats({
    required this.borrowedBooks,
    required this.returnedBooks,
    required this.dueSoon,
    required this.reservedBooks,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        borrowedBooks: json['borrowedBooks'] ?? json['issuedToday'] ?? 0,
        returnedBooks: json['returnedBooks'] ?? json['returnedToday'] ?? 0,
        dueSoon: json['dueSoon'] ?? json['pendingReturns'] ?? 0,
        reservedBooks: json['reservedBooks'] ?? 0,
      );
}

class DashboardService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /api/dashboard/stats — the 4 stat cards on the Staff Dashboard.
  Future<DashboardStats> getStats() async {
    try {
      final res = await _dio.get('/dashboard/stats');
      return DashboardStats.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
