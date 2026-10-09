import 'api_client.dart';

class FeedbackItem {
  final String id;
  final String senderId;
  final String senderName;
  final String senderType;
  final String message;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;

  const FeedbackItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    required this.status,
    this.adminResponse,
    required this.createdAt,
  });

  bool get isResolved => status.toUpperCase() == 'RESOLVED';

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'].toString(),
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderType: json['senderType'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'OPEN',
      adminResponse: json['adminResponse'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Students/Staff submit feedback via POST; the Admin/Librarian reviews and
/// resolves it here — this is what the admin sees on the Settings screen.
class FeedbackRemoteService {
  FeedbackRemoteService(this._client);
  final ApiClient _client;

  Future<List<FeedbackItem>> getAll() async {
    final response = await _client.get('/feedback');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.cast<Map<String, dynamic>>().map(FeedbackItem.fromJson).toList();
  }

  Future<void> submit({
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) {
    return _client.post('/feedback', data: {
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'message': message,
    });
  }

  Future<void> resolve(String id) => _client.dio.patch('/feedback/$id/resolve');
}
