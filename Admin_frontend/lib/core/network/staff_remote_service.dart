import '../../models/student.dart';
import 'api_client.dart';

/// Talks to the real `/api/v1/staff` endpoints on the Spring Boot backend.
/// Handles both regular teaching Staff and Librarian accounts — any number
/// of librarians can be created here, each with their own staffId + password.
/// Account creation enforces the college's own Gmail domain server-side.
class StaffRemoteService {
  StaffRemoteService(this._client);
  final ApiClient _client;

  Staff _fromJson(Map<String, dynamic> json) => Staff.fromJson(json);

  Future<List<Staff>> getAll({String? query}) async {
    final response = await _client.get('/staff', query: {
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.cast<Map<String, dynamic>>().map(_fromJson).toList();
  }

  /// [role] is 'STAFF' or 'LIBRARIAN'. [email] must be the college's own
  /// domain (e.g. ranjith@vvcoe.org) — enforced server-side.
  Future<Staff> create({
    required String staffId,
    required String name,
    required String department,
    required String designation,
    required String email,
    required String phone,
    required String password,
    required String role,
    int? borrowLimit,
  }) async {
    final response = await _client.post('/staff', data: {
      'staffId': staffId,
      'name': name,
      'department': department,
      'designation': designation,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      if (borrowLimit != null) 'borrowLimit': borrowLimit,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<Staff> update(String id, Map<String, dynamic> payload) async {
    final response = await _client.put('/staff/$id', data: payload);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<void> toggleBlock(String id) => _client.dio.patch('/staff/$id/toggle-block');

  Future<void> delete(String id) => _client.delete('/staff/$id');
}
