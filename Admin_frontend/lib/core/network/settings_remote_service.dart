import 'api_client.dart';

class LibrarySettingsModel {
  final String openingTime;
  final String closingTime;
  final String workingDays;
  final int maxBorrowLimitStudent;
  final int maxBorrowLimitStaff;
  final int maxReservationLimit;
  final int borrowDurationDays;
  final double finePerDay;
  final int extensionDaysAllowed;
  final String announcement;

  const LibrarySettingsModel({
    this.openingTime = '08:30',
    this.closingTime = '18:00',
    this.workingDays = 'Mon-Sat',
    this.maxBorrowLimitStudent = 3,
    this.maxBorrowLimitStaff = 5,
    this.maxReservationLimit = 2,
    this.borrowDurationDays = 14,
    this.finePerDay = 2.0,
    this.extensionDaysAllowed = 7,
    this.announcement = '',
  });

  LibrarySettingsModel copyWith({
    String? openingTime,
    String? closingTime,
    String? workingDays,
    int? maxBorrowLimitStudent,
    int? maxBorrowLimitStaff,
    int? maxReservationLimit,
    int? borrowDurationDays,
    double? finePerDay,
    int? extensionDaysAllowed,
    String? announcement,
  }) {
    return LibrarySettingsModel(
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      workingDays: workingDays ?? this.workingDays,
      maxBorrowLimitStudent: maxBorrowLimitStudent ?? this.maxBorrowLimitStudent,
      maxBorrowLimitStaff: maxBorrowLimitStaff ?? this.maxBorrowLimitStaff,
      maxReservationLimit: maxReservationLimit ?? this.maxReservationLimit,
      borrowDurationDays: borrowDurationDays ?? this.borrowDurationDays,
      finePerDay: finePerDay ?? this.finePerDay,
      extensionDaysAllowed: extensionDaysAllowed ?? this.extensionDaysAllowed,
      announcement: announcement ?? this.announcement,
    );
  }

  factory LibrarySettingsModel.fromJson(Map<String, dynamic> json) {
    return LibrarySettingsModel(
      openingTime: json['openingTime'] ?? '08:30',
      closingTime: json['closingTime'] ?? '18:00',
      workingDays: json['workingDays'] ?? 'Mon-Sat',
      maxBorrowLimitStudent: json['maxBorrowLimitStudent'] ?? 3,
      maxBorrowLimitStaff: json['maxBorrowLimitStaff'] ?? 5,
      maxReservationLimit: json['maxReservationLimit'] ?? 2,
      borrowDurationDays: json['borrowDurationDays'] ?? 14,
      finePerDay: (json['finePerDay'] ?? 2.0).toDouble(),
      extensionDaysAllowed: json['extensionDaysAllowed'] ?? 7,
      announcement: json['announcement'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': 1,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'workingDays': workingDays,
        'maxBorrowLimitStudent': maxBorrowLimitStudent,
        'maxBorrowLimitStaff': maxBorrowLimitStaff,
        'maxReservationLimit': maxReservationLimit,
        'borrowDurationDays': borrowDurationDays,
        'finePerDay': finePerDay,
        'extensionDaysAllowed': extensionDaysAllowed,
        'announcement': announcement,
      };
}

/// Library timing + borrowing/reservation rules — visible to every role,
/// editable only by Admin/Librarian (enforced server-side).
class SettingsRemoteService {
  SettingsRemoteService(this._client);
  final ApiClient _client;

  Future<LibrarySettingsModel> get() async {
    final response = await _client.get('/settings');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return LibrarySettingsModel.fromJson(data);
  }

  Future<LibrarySettingsModel> update(LibrarySettingsModel settings) async {
    final response = await _client.put('/settings', data: settings.toJson());
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return LibrarySettingsModel.fromJson(data);
  }
}
