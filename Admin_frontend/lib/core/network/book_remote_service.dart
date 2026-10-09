import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/book.dart';
import 'api_client.dart';

class BookSearchResult {
  final List<Book> books;
  final int totalPages;
  final int totalElements;
  final int page;

  const BookSearchResult({
    required this.books,
    required this.totalPages,
    required this.totalElements,
    required this.page,
  });
}

class BulkImportResult {
  final int totalRows;
  final int importedCount;
  final int skippedCount;
  final int durationMs;
  final List<String> errors;

  const BulkImportResult({
    required this.totalRows,
    required this.importedCount,
    required this.skippedCount,
    required this.durationMs,
    required this.errors,
  });

  factory BulkImportResult.fromJson(Map<String, dynamic> json) {
    return BulkImportResult(
      totalRows: json['totalRows'] ?? 0,
      importedCount: json['importedCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
      durationMs: json['durationMs'] ?? 0,
      errors: (json['errors'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

/// Talks to the real `/api/v1/books` endpoints on the Spring Boot backend.
/// This is what actually powers the search bar and bulk import against
/// MySQL — no mock data involved.
class BookRemoteService {
  BookRemoteService(this._client);
  final ApiClient _client;

  Book _bookFromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      publisher: json['publisher'] ?? '',
      isbn: json['isbn'] ?? '',
      edition: json['edition'] ?? '',
      category: json['category'] ?? '',
      department: json['department'] ?? '',
      rackNumber: json['rackNumber'] ?? '',
      shelfNumber: json['shelfNumber'] ?? '',
      regulation: json['regulation'] ?? '',
      totalCopies: json['totalCopies'] ?? 0,
      availableCopies: json['availableCopies'] ?? 0,
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      qrCode: json['qrCode'] ?? '',
      addedOn: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Hits GET /books/search — this is what the search bar calls on every
  /// keystroke (debounced on the UI side). Paginated so it stays fast
  /// even against a 10,000+ row catalogue.
  Future<BookSearchResult> search({
    String query = '',
    String? category,
    String? department,
    String? regulation,
    bool onlyAvailable = false,
    bool onlyIssued = false,
    bool onlyLowStock = false,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get('/books/search', query: {
      if (query.isNotEmpty) 'q': query,
      if (category != null) 'category': category,
      if (department != null) 'department': department,
      if (regulation != null) 'regulation': regulation,
      'onlyAvailable': onlyAvailable,
      'onlyIssued': onlyIssued,
      'onlyLowStock': onlyLowStock,
      'page': page,
      'size': size,
    });

    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final content = (data['content'] as List).cast<Map<String, dynamic>>();

    return BookSearchResult(
      books: content.map(_bookFromJson).toList(),
      totalPages: data['totalPages'] ?? 1,
      totalElements: data['totalElements'] ?? content.length,
      page: data['number'] ?? page,
    );
  }

  Future<Book> getById(String id) async {
    final response = await _client.get('/books/$id');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _bookFromJson(data);
  }

  Future<Book> create(Map<String, dynamic> bookPayload) async {
    final response = await _client.post('/books', data: bookPayload);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _bookFromJson(data);
  }

  Future<Book> update(String id, Map<String, dynamic> bookPayload) async {
    final response = await _client.put('/books/$id', data: bookPayload);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _bookFromJson(data);
  }

  Future<void> delete(String id) => _client.delete('/books/$id');

  /// Uploads/replaces a book's cover image. Returns the refreshed book
  /// (including the new `coverUrl`) on success — mirrors the profile
  /// avatar-upload pattern.
  Future<Book> uploadCover(String bookId, {required List<int> bytes, required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _client.dio.post('/books/$bookId/cover', data: formData);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _bookFromJson(data);
  }

  /// Uploads a raw .csv or .xlsx file straight to the backend, which parses
  /// it and batch-inserts every row into MySQL server-side. This is the
  /// "push an Excel sheet, it lands in the database" flow — nothing is
  /// parsed on the phone.
  Future<BulkImportResult> bulkImport(File file) async {
    return bulkImportBytes(await file.readAsBytes(), file.path.split('/').last);
  }

  /// Same as [bulkImport] but takes raw bytes + filename directly — use this
  /// when the file came from `file_picker` with `withData: true`, which is
  /// the reliable path on both mobile and web.
  Future<BulkImportResult> bulkImportBytes(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await _client.dio.post(
      '/books/bulk-import',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return BulkImportResult.fromJson(data);
  }
}
