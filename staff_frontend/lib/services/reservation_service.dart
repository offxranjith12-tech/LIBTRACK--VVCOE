import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class ReservationService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /api/reservations — all active reservations (not used by the staff module anymore).
  Future<List<Reservation>> getAll() async {
    try {
      final res = await _dio.get('/reservations');
      return (res.data as List).map((e) => Reservation.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /api/reservations/mine — "My Reservations": only the logged-in
  /// staff member's own active reservations (waiting or ready to collect).
  Future<List<Reservation>> getMine() async {
    try {
      final res = await _dio.get('/reservations/mine');
      return (res.data as List).map((e) => Reservation.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /api/reservations/mine/history — "My Reservations History": only the logged-in
  /// staff member's own history reservations.
  Future<List<Reservation>> getHistory() async {
    try {
      final res = await _dio.get('/reservations/mine/history');
      return (res.data as List).map((e) => Reservation.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/reservations/self — a staff member reserving a book for
  /// themselves. Holds a copy immediately if one is free, otherwise joins
  /// the queue ahead of student reservations.
  Future<Reservation> reserveForSelf(String bookId) async {
    try {
      final res = await _dio.post('/reservations/self', data: {'bookId': bookId});
      return Reservation.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/reservations/{id}/collect — staff has picked up their held book.
  Future<Reservation> collect(String id) async {
    try {
      final res = await _dio.post('/reservations/$id/collect');
      return Reservation.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/reservations — Join Queue screen, when a staff member
  /// reserves an unavailable book on behalf of a student.
  Future<Reservation> create({required String bookId, required String studentRegNo}) async {
    try {
      final res = await _dio.post('/reservations', data: {
        'bookId': bookId,
        'studentRegNo': studentRegNo,
      });
      return Reservation.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/reservations/{id}/approve — "Approve Reservation" button.
  Future<Reservation> approve(String id) async {
    try {
      final res = await _dio.post('/reservations/$id/approve');
      return Reservation.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/reservations/{id}/cancel — "Cancel Reservation" button.
  Future<Reservation> cancel(String id) async {
    try {
      final res = await _dio.post('/reservations/$id/cancel');
      return Reservation.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/reservations/{id}/notify — "Notify Student" button.
  Future<void> notifyStudent(String id) async {
    try {
      await _dio.post('/reservations/$id/notify');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
