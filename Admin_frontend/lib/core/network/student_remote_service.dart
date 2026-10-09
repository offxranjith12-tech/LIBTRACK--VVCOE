import '../../models/student.dart';
import 'api_client.dart';

/// Talks to the real `/api/v1/students` endpoints on the Spring Boot backend.
/// Account creation enforces the college's own Gmail domain server-side —
/// personal email addresses are rejected there even if this client sent one.
class StudentRemoteService {
  StudentRemoteService(this._client);
  final ApiClient _client;

  Student _fromJson(Map<String, dynamic> json) => Student.fromJson(json);

  Future<List<Student>> getAll({String? query}) async {
    final response = await _client.get('/students', query: {
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.cast<Map<String, dynamic>>().map(_fromJson).toList();
  }

  /// Creates a new student login. [email] must be the college's own domain
  /// (e.g. r23cs065@vvcoe.org) — personal Gmail/Yahoo addresses are rejected
  /// by the backend regardless of what's passed here.
  Future<Student> create({
    required String registerNumber,
    required String name,
    required String department,
    required int semester,
    required String email,
    required String phone,
    required String password,
    int? borrowLimit,
  }) async {
    final response = await _client.post('/students', data: {
      'registerNumber': registerNumber,
      'name': name,
      'department': department,
      'semester': semester,
      'email': email,
      'phone': phone,
      'password': password,
      if (borrowLimit != null) 'borrowLimit': borrowLimit,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<Student> update(String id, Map<String, dynamic> payload) async {
    final response = await _client.put('/students/$id', data: payload);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<void> toggleBlock(String id) => _client.dio.patch('/students/$id/toggle-block');

  Future<void> delete(String id) => _client.delete('/students/$id');
}
