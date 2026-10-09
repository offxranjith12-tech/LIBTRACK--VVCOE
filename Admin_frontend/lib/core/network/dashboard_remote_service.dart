import 'api_client.dart';

/// Talks to `/api/v1/dashboard/stats` — real, live counts straight from
/// MySQL (total/available/issued books, students, staff, overdue count,
/// fine collected). Previously the Dashboard screen computed these from
/// local mock data instead of calling this endpoint, which is why bulk
/// imports and other real changes never showed up there.
class DashboardRemoteService {
  DashboardRemoteService(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> getStats() async {
    final response = await _client.get('/dashboard/stats');
    return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }
}
