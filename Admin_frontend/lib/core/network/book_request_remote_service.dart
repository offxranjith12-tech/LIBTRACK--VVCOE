import '../../models/book_request.dart';
import 'api_client.dart';

/// Talks to `/api/v1/book-requests` — a student's request to borrow a
/// specific book, which the admin reviews here (approve & issue, or reject).
class BookRequestRemoteService {
  BookRequestRemoteService(this._client);
  final ApiClient _client;

  BookRequest _fromJson(Map<String, dynamic> json) => BookRequest.fromJson(json);

  /// Admin's inbox. Pass a status ('PENDING', 'APPROVED', 'REJECTED', 'ISSUED')
  /// to filter, or leave null for everything.
  Future<List<BookRequest>> getAll({String? status}) async {
    final response = await _client.get('/book-requests', query: status == null ? null : {'status': status});
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.cast<Map<String, dynamic>>().map(_fromJson).toList();
  }

  Future<BookRequest> create({required String bookId, required String studentId, String? notes}) async {
    final response = await _client.post('/book-requests', data: {
      'bookId': bookId,
      'studentId': studentId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  /// Verifies eligibility and issues the book to the requesting student in one step.
  Future<BookRequest> approve(String requestId, {int? durationDays}) async {
    final response = await _client.dio.post(
      '/book-requests/$requestId/approve',
      queryParameters: durationDays == null ? null : {'durationDays': durationDays},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<BookRequest> reject(String requestId, {String? reason}) async {
    final response = await _client.post('/book-requests/$requestId/reject', data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }
}
