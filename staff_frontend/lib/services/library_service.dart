import 'package:dio/dio.dart';
import 'api_client.dart';

class DaySchedule {
  final String day;
  final String hours;
  final bool closed;
  const DaySchedule({required this.day, required this.hours, required this.closed});

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        day: json['day']?.toString() ?? '',
        hours: json['hours']?.toString() ?? '',
        closed: json['closed'] == true,
      );
}

class LibraryTimings {
  final List<DaySchedule> schedule;
  final String note;
  const LibraryTimings({required this.schedule, required this.note});

  factory LibraryTimings.fromJson(Map<String, dynamic> json) => LibraryTimings(
        schedule: (json['schedule'] as List?)
                ?.map((e) => DaySchedule.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        note: json['note']?.toString() ?? '',
      );
}

class RuleSection {
  final String title;
  final List<String> points;
  const RuleSection({required this.title, required this.points});

  factory RuleSection.fromJson(Map<String, dynamic> json) => RuleSection(
        title: json['title']?.toString() ?? '',
        points: (json['points'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class LibraryRules {
  final String title;
  final String version;
  final List<RuleSection> sections;
  const LibraryRules({required this.title, required this.version, required this.sections});

  factory LibraryRules.fromJson(Map<String, dynamic> json) => LibraryRules(
        title: json['title']?.toString() ?? 'Library Rules & Regulations',
        version: json['version']?.toString() ?? '',
        sections: (json['sections'] as List?)
                ?.map((e) => RuleSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class LibraryService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /api/library/timings — the Library Timings screen.
  Future<LibraryTimings> getTimings() async {
    try {
      final res = await _dio.get('/library/timings');
      if (res.data is Map<String, dynamic>) {
        return LibraryTimings.fromJson(res.data as Map<String, dynamic>);
      }
      return const LibraryTimings(schedule: [], note: '');
    } on DioException {
      return const LibraryTimings(
        schedule: [
          DaySchedule(day: 'Monday', hours: '9:00 AM - 5:00 PM', closed: false),
          DaySchedule(day: 'Tuesday', hours: '9:00 AM - 5:00 PM', closed: false),
          DaySchedule(day: 'Wednesday', hours: '9:00 AM - 5:00 PM', closed: false),
          DaySchedule(day: 'Thursday', hours: '9:00 AM - 5:00 PM', closed: false),
          DaySchedule(day: 'Friday', hours: '9:00 AM - 5:00 PM', closed: false),
          DaySchedule(day: 'Saturday', hours: '10:00 AM - 2:00 PM', closed: false),
          DaySchedule(day: 'Sunday', hours: 'Closed', closed: true),
        ],
        note: 'Default timings shown. Server is currently offline.',
      );
    }
  }

  /// GET /api/library/rules — the Library Rules screen.
  Future<LibraryRules> getRules() async {
    try {
      final res = await _dio.get('/library/rules');
      if (res.data is Map<String, dynamic>) {
        return LibraryRules.fromJson(res.data as Map<String, dynamic>);
      }
      return const LibraryRules(title: 'Library Rules', version: '', sections: []);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
