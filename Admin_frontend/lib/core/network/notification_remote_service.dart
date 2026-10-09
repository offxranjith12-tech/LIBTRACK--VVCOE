import 'api_client.dart';

/// Broadcast-only notifications — there is no individual/per-user target,
/// only ALL_STUDENTS / ALL_STAFF / ALL, matching the backend contract.
class RemoteNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String audience;
  final DateTime sentOn;

  const RemoteNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.audience,
    required this.sentOn,
  });

  factory RemoteNotification.fromJson(Map<String, dynamic> json) {
    return RemoteNotification(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'ANNOUNCEMENT',
      audience: json['audience'] ?? 'ALL',
      sentOn: DateTime.tryParse(json['sentOn'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationRemoteService {
  NotificationRemoteService(this._client);
  final ApiClient _client;

  Future<List<RemoteNotification>> getAll() async {
    final response = await _client.get('/notifications');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.cast<Map<String, dynamic>>().map(RemoteNotification.fromJson).toList();
  }

  Future<void> send({required String title, required String message, required String type, required String audience}) {
    return _client.post('/notifications', data: {
      'title': title,
      'message': message,
      'type': type,
      'audience': audience,
    });
  }

  Future<void> delete(String id) => _client.delete('/notifications/$id');
}
