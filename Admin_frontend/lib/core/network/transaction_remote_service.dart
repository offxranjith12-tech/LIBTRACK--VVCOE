import '../../models/transaction.dart';
import 'api_client.dart';

/// Talks to the real `/api/v1/transactions` endpoints — including the admin
/// actions requested for LibTrack: manually marking a fine PAID/UNPAID/WAIVED
/// (updates the borrower's profile), manually correcting a transaction's
/// status, and approving/rejecting a borrower's request for extra time.
class TransactionRemoteService {
  TransactionRemoteService(this._client);
  final ApiClient _client;

  LibraryTransaction _fromJson(Map<String, dynamic> json) => LibraryTransaction.fromJson(json);

  Future<List<LibraryTransaction>> getAll() async {
    final response = await _client.get('/transactions');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.cast<Map<String, dynamic>>().map(_fromJson).toList();
  }

  Future<List<LibraryTransaction>> getActive() async {
    final response = await _client.get('/transactions/active');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.cast<Map<String, dynamic>>().map(_fromJson).toList();
  }

  Future<LibraryTransaction> issueBook({
    required String bookId,
    required String borrowerId,
    required String borrowerType,
  }) async {
    final response = await _client.post('/transactions/issue', data: {
      'bookId': bookId,
      'borrowerId': borrowerId,
      'borrowerType': borrowerType,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<LibraryTransaction> returnBook(String transactionId, {bool fineCollected = false}) async {
    final response = await _client.post('/transactions/return', data: {
      'transactionId': transactionId,
      'fineCollected': fineCollected,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  /// Admin marks the fine PAID / UNPAID / WAIVED — this is what updates the
  /// student/staff's profile once they've actually paid at the desk.
  Future<LibraryTransaction> updateFineStatus(String transactionId, String status, {String? paymentMethod}) async {
    final response = await _client.dio.patch('/transactions/$transactionId/fine-status', data: {
      'status': status,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  /// Admin manually corrects a transaction's status (e.g. return that wasn't
  /// scanned via QR gets marked RETURNED directly by the admin).
  Future<LibraryTransaction> manualStatusUpdate(String transactionId, String status) async {
    final response = await _client.dio.patch('/transactions/$transactionId/manual-status', data: {'status': status});
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<LibraryTransaction> requestExtension(String transactionId, {int? extraDays}) async {
    final response = await _client.post('/transactions/extension/request', data: {
      'transactionId': transactionId,
      if (extraDays != null) 'extraDays': extraDays,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<LibraryTransaction> approveExtension(String transactionId) async {
    final response = await _client.dio.patch('/transactions/$transactionId/extension/approve');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }

  Future<LibraryTransaction> rejectExtension(String transactionId) async {
    final response = await _client.dio.patch('/transactions/$transactionId/extension/reject');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _fromJson(data);
  }
}
