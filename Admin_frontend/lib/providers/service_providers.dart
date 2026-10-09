import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/auth_service.dart';
import '../core/network/book_remote_service.dart';
import '../core/network/student_remote_service.dart';
import '../core/network/staff_remote_service.dart';
import '../core/network/settings_remote_service.dart';
import '../core/network/feedback_remote_service.dart';
import '../core/network/notification_remote_service.dart';
import '../core/network/transaction_remote_service.dart';
import '../core/network/report_remote_service.dart';
import '../core/network/me_remote_service.dart';
import '../core/network/dashboard_remote_service.dart';
import '../core/network/book_request_remote_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(apiClientProvider)));

final bookRemoteServiceProvider = Provider<BookRemoteService>((ref) => BookRemoteService(ref.watch(apiClientProvider)));

final studentRemoteServiceProvider = Provider<StudentRemoteService>((ref) => StudentRemoteService(ref.watch(apiClientProvider)));

final staffRemoteServiceProvider = Provider<StaffRemoteService>((ref) => StaffRemoteService(ref.watch(apiClientProvider)));

final settingsRemoteServiceProvider = Provider<SettingsRemoteService>((ref) => SettingsRemoteService(ref.watch(apiClientProvider)));

final feedbackRemoteServiceProvider = Provider<FeedbackRemoteService>((ref) => FeedbackRemoteService(ref.watch(apiClientProvider)));

final notificationRemoteServiceProvider = Provider<NotificationRemoteService>((ref) => NotificationRemoteService(ref.watch(apiClientProvider)));

final transactionRemoteServiceProvider = Provider<TransactionRemoteService>((ref) => TransactionRemoteService(ref.watch(apiClientProvider)));
final bookRequestRemoteServiceProvider = Provider<BookRequestRemoteService>((ref) => BookRequestRemoteService(ref.watch(apiClientProvider)));

final reportRemoteServiceProvider = Provider<ReportRemoteService>((ref) => ReportRemoteService(ref.watch(apiClientProvider)));

final meRemoteServiceProvider = Provider<MeRemoteService>((ref) => MeRemoteService(ref.watch(apiClientProvider)));

final dashboardRemoteServiceProvider = Provider<DashboardRemoteService>((ref) => DashboardRemoteService(ref.watch(apiClientProvider)));
