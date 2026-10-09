import 'package:dio/dio.dart';
import 'api_client.dart';

/// Downloads the real transactions report generated server-side
/// (`GET /api/v1/reports/transactions/download`) as CSV bytes, which the
/// Reports screen then saves/shares on-device.
class ReportRemoteService {
  ReportRemoteService(this._client);
  final ApiClient _client;

  Future<List<int>> downloadTransactionsReport({String? status}) async {
    final response = await _client.dio.get<List<int>>(
      '/reports/transactions/download',
      queryParameters: {if (status != null) 'status': status},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}
