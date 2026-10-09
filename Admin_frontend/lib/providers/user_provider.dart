import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/me_remote_service.dart';
import '../models/student.dart';
import 'service_providers.dart';

/// Real backend-backed Student list. Loads from `/api/v1/students` on start
/// and refreshes after every create/toggle-block/delete so the Users screen
/// always reflects MySQL.
class StudentsNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  StudentsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final dynamic _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleBlock(String id) async {
    await _service.toggleBlock(id);
    await load();
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _service.update(id, payload);
    await load();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await load();
  }
}

class StaffNotifier extends StateNotifier<AsyncValue<List<Staff>>> {
  StaffNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final dynamic _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleBlock(String id) async {
    await _service.toggleBlock(id);
    await load();
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _service.update(id, payload);
    await load();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await load();
  }
}

final studentsNotifierProvider = StateNotifierProvider<StudentsNotifier, AsyncValue<List<Student>>>(
  (ref) => StudentsNotifier(ref.watch(studentRemoteServiceProvider)),
);

final staffNotifierProvider = StateNotifierProvider<StaffNotifier, AsyncValue<List<Staff>>>(
  (ref) => StaffNotifier(ref.watch(staffRemoteServiceProvider)),
);

/// Plain-list compatibility providers for screens that just need the current
/// snapshot (e.g. issuing a book, generating reports) without handling
/// loading/error states themselves.
final studentsProvider = Provider<List<Student>>((ref) => ref.watch(studentsNotifierProvider).valueOrNull ?? []);
final staffProvider = Provider<List<Staff>>((ref) => ref.watch(staffNotifierProvider).valueOrNull ?? []);

final userSearchQueryProvider = StateProvider<String>((ref) => '');

/// Optional department filter for User Management — lets the admin narrow
/// Students/Staff down to one department in addition to free-text search.
final userDepartmentFilterProvider = StateProvider<String?>((ref) => null);

final filteredStudentsProvider = Provider<List<Student>>((ref) {
  final query = ref.watch(userSearchQueryProvider).toLowerCase();
  final dept = ref.watch(userDepartmentFilterProvider);
  final students = ref.watch(studentsProvider);
  return students.where((s) {
    final matchesQuery = query.isEmpty ||
        s.name.toLowerCase().contains(query) ||
        s.registerNumber.toLowerCase().contains(query) ||
        s.department.toLowerCase().contains(query);
    final matchesDept = dept == null || s.department == dept;
    return matchesQuery && matchesDept;
  }).toList();
});

final filteredStaffProvider = Provider<List<Staff>>((ref) {
  final query = ref.watch(userSearchQueryProvider).toLowerCase();
  final dept = ref.watch(userDepartmentFilterProvider);
  final staff = ref.watch(staffProvider);
  return staff.where((s) {
    final matchesQuery = query.isEmpty ||
        s.name.toLowerCase().contains(query) ||
        s.staffId.toLowerCase().contains(query) ||
        s.department.toLowerCase().contains(query);
    final matchesDept = dept == null || s.department == dept;
    return matchesQuery && matchesDept;
  }).toList();
});

// --- Logged-in user's own profile (Admin / Staff / Librarian / Student) -----

class MeProfileNotifier extends StateNotifier<AsyncValue<MeProfile>> {
  MeProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final MeRemoteService _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.getMe();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update({String? name, String? phone, String? email}) async {
    final updated = await _service.updateMe(name: name, phone: phone, email: email);
    state = AsyncValue.data(updated);
  }

  Future<void> uploadAvatar({required List<int> bytes, required String filename}) async {
    final updated = await _service.uploadAvatar(bytes: bytes, filename: filename);
    state = AsyncValue.data(updated);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) {
    return _service.changePassword(currentPassword: currentPassword, newPassword: newPassword);
  }
}

final meProfileProvider = StateNotifierProvider<MeProfileNotifier, AsyncValue<MeProfile>>(
  (ref) => MeProfileNotifier(ref.watch(meRemoteServiceProvider)),
);
