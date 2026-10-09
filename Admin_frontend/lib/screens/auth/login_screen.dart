import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/auth_service.dart';
import '../../providers/service_providers.dart';
import '../../widgets/server_connection_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController(text: 'VVCE-LIB-ADM-001');
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).login(
            adminId: _idController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        setState(() => _errorMessage =
            "Can't reach the LibTrack server. Tap the settings icon above to check the server address.");
      } else {
        setState(() => _errorMessage = 'Something went wrong: ${e.message ?? e}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Server Connection',
                  icon: Icon(Icons.settings_ethernet_rounded, color: AppColors.textSecondary),
                  onPressed: () => showServerConnectionSheet(context),
                ),
              ),
              Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_library_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.collegeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  Text('Admin ID', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
                  ),
                  const SizedBox(height: 18),
                  Text('Password', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
