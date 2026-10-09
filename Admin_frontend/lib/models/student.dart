import '../core/constants/app_constants.dart';

enum UserStatus { active, blocked, suspended }

UserStatus _statusFromString(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'BLOCKED':
      return UserStatus.blocked;
    case 'SUSPENDED':
      return UserStatus.suspended;
    default:
      return UserStatus.active;
  }
}

/// True only for the college's own Gmail domain (e.g. r23cs065@vvcoe.org).
/// Personal Gmail/Yahoo/etc. addresses must never be accepted for LibTrack
/// student/staff/librarian accounts.
bool isCollegeEmail(String email) {
  final trimmed = email.trim().toLowerCase();
  final parts = trimmed.split('@');
  return parts.length == 2 && parts[1] == AppConstants.collegeEmailDomain;
}

class Student {
  final String id;
  final String registerNumber;
  final String name;
  final String department;
  final int semester;
  final String email;
  final String phone;
  final String photoUrl;
  final int borrowedBooksCount;
  final int borrowLimit;
  final UserStatus status;
  final DateTime joinedOn;

  const Student({
    required this.id,
    required this.registerNumber,
    required this.name,
    required this.department,
    required this.semester,
    required this.email,
    required this.phone,
    this.photoUrl = '',
    required this.borrowedBooksCount,
    this.borrowLimit = 3,
    this.status = UserStatus.active,
    required this.joinedOn,
  });

  bool get canBorrow => status == UserStatus.active && borrowedBooksCount < borrowLimit;

  Student copyWith({UserStatus? status, int? borrowedBooksCount}) {
    return Student(
      id: id,
      registerNumber: registerNumber,
      name: name,
      department: department,
      semester: semester,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      borrowedBooksCount: borrowedBooksCount ?? this.borrowedBooksCount,
      borrowLimit: borrowLimit,
      status: status ?? this.status,
      joinedOn: joinedOn,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(),
      registerNumber: json['registerNumber'] ?? '',
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      semester: json['semester'] ?? 1,
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      borrowedBooksCount: json['borrowedBooksCount'] ?? 0,
      borrowLimit: json['borrowLimit'] ?? 3,
      status: _statusFromString(json['status']),
      joinedOn: DateTime.tryParse(json['joinedOn'] ?? '') ?? DateTime.now(),
    );
  }
}

/// STAFF = regular teaching faculty. LIBRARIAN = library-desk staff with a
/// full login of their own — the library can have any number of librarians,
/// each with an independent staffId + password.
enum StaffRole { staff, librarian }

StaffRole _roleFromString(String? value) {
  return (value ?? '').toUpperCase() == 'LIBRARIAN' ? StaffRole.librarian : StaffRole.staff;
}

class Staff {
  final String id;
  final String staffId;
  final String name;
  final String department;
  final String designation;
  final String email;
  final String phone;
  final String photoUrl;
  final int borrowedBooksCount;
  final int borrowLimit;
  final UserStatus status;
  final StaffRole role;
  final DateTime joinedOn;

  const Staff({
    required this.id,
    required this.staffId,
    required this.name,
    required this.department,
    required this.designation,
    required this.email,
    required this.phone,
    this.photoUrl = '',
    required this.borrowedBooksCount,
    this.borrowLimit = 5,
    this.status = UserStatus.active,
    this.role = StaffRole.staff,
    required this.joinedOn,
  });

  bool get canBorrow => status == UserStatus.active && borrowedBooksCount < borrowLimit;
  bool get isLibrarian => role == StaffRole.librarian;

  Staff copyWith({UserStatus? status, int? borrowedBooksCount}) {
    return Staff(
      id: id,
      staffId: staffId,
      name: name,
      department: department,
      designation: designation,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      borrowedBooksCount: borrowedBooksCount ?? this.borrowedBooksCount,
      borrowLimit: borrowLimit,
      status: status ?? this.status,
      role: role,
      joinedOn: joinedOn,
    );
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'].toString(),
      staffId: json['staffId'] ?? '',
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      borrowedBooksCount: json['borrowedBooksCount'] ?? 0,
      borrowLimit: json['borrowLimit'] ?? 5,
      status: _statusFromString(json['status']),
      role: _roleFromString(json['role']),
      joinedOn: DateTime.tryParse(json['joinedOn'] ?? '') ?? DateTime.now(),
    );
  }
}

class AdminProfile {
  final String id;
  final String adminId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String photoUrl;
  final DateTime lastLogin;

  const AdminProfile({
    required this.id,
    required this.adminId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl = '',
    required this.lastLogin,
  });
}
