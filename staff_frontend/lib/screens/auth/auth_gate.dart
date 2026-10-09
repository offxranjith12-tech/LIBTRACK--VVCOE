import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/staff_providers.dart';
import '../../theme/app_theme.dart';
import '../staff/staff_shell.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  static const String _username = 'anitha.r';
  static const String _password = 'staff123';

  bool _attempted = false;
  String? _error;

  Future<void> _autoLogin() async {
    try {
      await ref.read(authServiceProvider).login(_username, _password);

      ref.invalidate(isLoggedInProvider);
      ref.invalidate(currentStaffProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Could not reach the server. Is the backend running?";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);

    return loggedIn.when(
      data: (isLoggedIn) {
        if (isLoggedIn) {
          return const StaffShell();
        }

        if (!_attempted) {
          _attempted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoLogin();
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: _error == null
                ? const CircularProgressIndicator(
              color: AppColors.primary,
            )
                : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.danger,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _attempted = false;
                      });
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),

      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}