import 'package:dio/dio.dart';
import 'api_client.dart';

class MeProfile {
  final String id;
  final String loginId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? department;
  final String? designationOrSemester;
  final String? avatarUrl;

  const MeProfile({
    required this.id,
    required this.loginId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.department,
    this.designationOrSemester,
    this.avatarUrl,
  });

  factory MeProfile.fromJson(Map<String, dynamic> json) {
    return MeProfile(
      id: json['id'].toString(),
      loginId: json['loginId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      department: json['department'],
      designationOrSemester: json['designationOrSemester'],
      avatarUrl: json['avatarUrl'],
    );
  }
}

/// Talks to `/api/v1/me` — resolves whichever account is logged in
/// (Admin, Staff, Librarian, or Student) from the JWT itself, so the same
/// calls power "Edit Profile", "Change Password", and the profile picture
/// upload for every role.
class MeRemoteService {
  MeRemoteService(this._client);
  final ApiClient _client;

  Future<MeProfile> getMe() async {
    final response = await _client.get('/me');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return MeProfile.fromJson(data);
  }

  Future<MeProfile> updateMe({String? name, String? phone, String? email}) async {
    final response = await _client.put('/me', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return MeProfile.fromJson(data);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) {
    return _client.post('/me/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Uploads a new profile picture. Returns the refreshed profile
  /// (including the new `avatarUrl`) on success.
  Future<MeProfile> uploadAvatar({required List<int> bytes, required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _client.dio.post('/me/avatar', data: formData);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return MeProfile.fromJson(data);
  }
}
