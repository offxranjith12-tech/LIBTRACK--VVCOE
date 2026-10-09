class AppConstants {
  AppConstants._();

  static const String appName = 'LibTrack';
  static const String collegeName = 'V V College of Engineering';
  static const String libraryName = 'Central Library';

  // API
  // Local backend via Docker/Maven: http://localhost:8080/api/v1
  // Android emulator talking to a host machine: http://10.0.2.2:8080/api/v1
  // Physical phone on the same WiFi as your computer: http://<your-computer-LAN-IP>:8080/api/v1
  // Production: https://your-real-domain.com/api/v1
  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  // Fine
  static const double finePerDay = 2.0;
  static const int defaultBorrowLimitStudent = 3;
  static const int defaultBorrowLimitStaff = 5;
  static const int defaultBorrowDurationDays = 14;
  static const int defaultReservationLimit = 2;

  static const List<String> departments = [
    'CSE',
    'ECE',
    'EEE',
    'MECH',
    'CIVIL',
    'IT',
    'AI & DS',
  ];

  static const List<String> categories = [
    'Textbook',
    'Reference',
    'Fiction',
    'Non-Fiction',
    'Journal',
    'Thesis',
    'Magazine',
    'Government Exam',
    'Religious - Hindu',
    'Religious - Christian',
    'Religious - Islamic',
    'Novel',
    'Law',
    'Management',
    'Aptitude',
  ];

  /// Curriculum regulation years — used on Textbooks so students/staff can
  /// filter/search by the syllabus regulation their book belongs to
  /// (e.g. "R2021" vs "R2023").
  static const List<String> regulations = [
    'R2017',
    'R2019',
    'R2021',
    'R2023',
  ];

  /// Only college-issued email addresses on this domain may be used to
  /// create Student/Staff/Librarian accounts (e.g. r23cs065@vvcoe.org).
  static const String collegeEmailDomain = 'vvcoe.org';
}
