import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/book.dart';
import '../models/borrowed_book.dart';
import '../models/notification_model.dart';
import '../models/reservation.dart';
import '../models/student.dart';
import 'mock_data_service.dart';

/// Central HTTP client for the LibTrack Spring Boot backend.
///
/// Point [baseUrl] at your Spring Boot server, e.g. http://10.0.2.2:8080/api
/// (10.0.2.2 is the Android emulator's alias for your machine's localhost;
/// use your PC's LAN IP, e.g. http://192.168.1.5:8080/api, for a real phone).
///
/// Every method below has two paths:
///   - useMockData = true  -> returns realistic in-memory demo data instantly,
///     so the app runs and demos perfectly with zero setup.
///   - useMockData = false -> calls the real Spring Boot + MySQL backend
///     included in the /backend folder of this project.
///
/// Flip [useMockData] to false once your backend is running and reachable.
class ApiService {
  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            (kIsWeb
                ? 'http://localhost:8080/api'
                : 'http://10.0.2.2:8080/api');

  final String baseUrl;

  /// Set this to false after starting the Spring Boot backend (see
  /// /backend/README.md) to switch the whole app over to live data.
  final bool useMockData = false;

  final _storage = const FlutterSecureStorage();
  late final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

  Dio get client => _dio;

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  /// Returns the logged-in Student on success, or null if the register
  /// number / password combination is wrong. Network/server errors are
  /// thrown so the caller can show a distinct "couldn't reach server"
  /// message instead of "wrong password".
  Future<Student?> login(String registerNumber, String password) async {
    if (useMockData) {
      await _storage.write(key: 'jwt_token', value: 'mock.jwt.token');
      return MockDataService.currentStudent;
    }
    try {
      final res = await _dio.post('/auth/login', data: {
        'registerNumber': registerNumber,
        'password': password,
      });
      final token = res.data['token'] as String;
      await _storage.write(key: 'jwt_token', value: token);
      return Student.fromJson(res.data['student'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null; // wrong credentials
      rethrow; // network/server error - let the caller show that distinctly
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> hasStoredToken() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> changePassword(String studentId, String currentPassword, String newPassword) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }
    await _dio.put('/students/$studentId/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> submitFeedback(String studentId, String category, String message) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }
    await _dio.post('/feedback', data: {
      'studentId': studentId,
      'category': category,
      'message': message,
    });
  }

  // ---------------------------------------------------------------------
  // Student profile
  // ---------------------------------------------------------------------

  Future<Student> fetchStudent(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockDataService.currentStudent;
    }
    final res = await _dio.get('/students/$id');
    return Student.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Student> updateStudent(String id, {String? name, String? email, String? phone}) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockDataService.currentStudent.copyWith(name: name, email: email, phone: phone);
    }
    final res = await _dio.put('/students/$id', data: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    return Student.fromJson(res.data as Map<String, dynamic>);
  }

  /// Uploads a new profile photo (multipart) and returns the photo URL
  /// the backend stored it under.
  Future<String> uploadProfileImage(String studentId, String filePath) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return filePath;
    }
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/students/$studentId/profile-image', data: form);
    return res.data['photoUrl'] as String;
  }

  // ---------------------------------------------------------------------
  // Books
  // ---------------------------------------------------------------------

  Future<List<Book>> searchBooks({
    String query = '',
    String? category,
    String? department,
    String? author,
    String? rack,
    BookAvailability? availability,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return MockDataService.search(
        query: query,
        category: category,
        department: department,
        author: author,
        rack: rack,
        availability: availability,
      );
    }
    final res = await _dio.get('/books', queryParameters: {
      if (query.isNotEmpty) 'query': query,
      if (category != null && category != 'All') 'category': category,
      if (department != null && department != 'All') 'department': department,
      if (author != null && author != 'All') 'author': author,
      if (rack != null && rack != 'All') 'rack': rack,
      if (availability != null) 'availability': availability.name,
    });
    return (res.data as List).map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Book> fetchBookById(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      return MockDataService.books.firstWhere((b) => b.id == id);
    }
    final res = await _dio.get('/books/$id');
    return Book.fromJson(res.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Borrowed books
  // ---------------------------------------------------------------------

  Future<List<BorrowedBook>> fetchBorrowedBooks(String studentId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockDataService.borrowedBooks;
    }
    final res = await _dio.get('/students/$studentId/borrowed-books');
    return (res.data as List).map((e) => BorrowedBook.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> renewBorrowedBook(String borrowRecordId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return;
    }
    await _dio.post('/borrowed-books/$borrowRecordId/renew');
  }

  // ---------------------------------------------------------------------
  // Reservations
  // ---------------------------------------------------------------------

  Future<List<Reservation>> fetchReservations(String studentId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return MockDataService.reservations;
    }
    final res = await _dio.get('/students/$studentId/reservations');
    return (res.data as List).map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Reservation> createReservation(String studentId, String bookId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      final book = MockDataService.books.firstWhere((b) => b.id == bookId);
      return Reservation(
        id: 'r_mock_${DateTime.now().millisecondsSinceEpoch}',
        book: book,
        reservationDate: DateTime.now(),
        queuePosition: 1,
        expectedAvailability: DateTime.now().add(const Duration(days: 3)),
      );
    }
    final res = await _dio.post('/reservations', data: {'studentId': studentId, 'bookId': bookId});
    return Reservation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> cancelReservation(String reservationId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }
    await _dio.delete('/reservations/$reservationId');
  }

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------

  Future<List<LibNotification>> fetchNotifications(String studentId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      return MockDataService.notifications;
    }
    final res = await _dio.get('/students/$studentId/notifications');
    return (res.data as List).map((e) => LibNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 80));
      return;
    }
    await _dio.put('/notifications/$notificationId/read');
  }

  // ---------------------------------------------------------------------
  // Dashboard stats
  // ---------------------------------------------------------------------

  /// Returns raw stat fields matching DashboardStats in app_providers.dart:
  /// { borrowed, reserved, dueSoon, pendingFine, totalBorrowedAllTime,
  ///   totalReturned, overdueCount }
  Future<Map<String, dynamic>> fetchDashboardStats(String studentId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 150));
      final borrowed = MockDataService.borrowedBooks;
      final issued = borrowed.where((b) => b.status == BorrowStatus.issued || b.status == BorrowStatus.overdue);
      return {
        'borrowed': issued.length,
        'reserved': MockDataService.reservations.length,
        'dueSoon': borrowed.where((b) => b.isDueSoon || b.status == BorrowStatus.overdue).length,
        'pendingFine': MockDataService.pendingFine,
        'totalBorrowedAllTime': borrowed.length,
        'totalReturned': borrowed.where((b) => b.status == BorrowStatus.returned).length,
        'overdueCount': borrowed.where((b) => b.status == BorrowStatus.overdue).length,
      };
    }
    final res = await _dio.get('/students/$studentId/dashboard-stats');
    return res.data as Map<String, dynamic>;
  }
}
