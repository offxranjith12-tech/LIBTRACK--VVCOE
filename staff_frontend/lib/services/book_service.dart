import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class BookService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /api/books/search — Search Books screen (query + filter chips).
  Future<List<Book>> search({
    String? query,
    String? category,
    String? department,
    String? author,
    String? rack,
    String? shelf,
    String? regulation,
    String? availability,
  }) async {
    try {
      final res = await _dio.get('/books/search', queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
        if (category != null) 'category': category,
        if (department != null) 'department': department,
        if (author != null) 'author': author,
        if (rack != null) 'rack': rack,
        if (shelf != null) 'shelf': shelf,
        if (regulation != null) 'regulation': regulation,
        if (availability != null) 'availability': availability,
      });
      return (res.data as List).map((e) => Book.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /api/books/{id} — Book Details screen.
  Future<Book> getById(String id) async {
    try {
      final res = await _dio.get('/books/$id');
      return Book.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /api/books/isbn/{isbn} — looks up a book by its ISBN.
  Future<Book> getByIsbn(String isbn) async {
    try {
      final res = await _dio.get('/books/isbn/$isbn');
      return Book.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
