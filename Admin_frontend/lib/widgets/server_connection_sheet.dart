import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/network/api_client.dart';

/// Lets whoever is setting up the app point it at the right backend.
/// Reachable from the Login screen (so it works even before signing in)
/// and from Settings (for admins who need to switch servers later).
///
/// This exists because the app ships with `http://localhost:8080/api/v1`
/// baked in as a *default* — that only resolves correctly on the same
/// machine the backend runs on. On a real phone, `localhost` means the
/// phone itself, so every request fails until this is pointed at the
/// backend's real LAN IP or domain.
Future<void> showServerConnectionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => const _ServerConnectionSheet(),
  );
}

class _ServerConnectionSheet extends StatefulWidget {
  const _ServerConnectionSheet();

  @override
  State<_ServerConnectionSheet> createState() => _ServerConnectionSheetState();
}

class _ServerConnectionSheetState extends State<_ServerConnectionSheet> {
  late final TextEditingController _controller;
  bool _testing = false;
  bool? _lastTestOk;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiClient.instance.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _lastTestOk = null;
    });
    // Apply (without persisting yet) so the test hits the URL being edited.
    final previous = ApiClient.instance.baseUrl;
    await ApiClient.instance.setBaseUrl(_controller.text);
    final ok = await ApiClient.instance.testConnection();
    if (!ok) {
      // Don't leave a broken URL active if the test failed and the user
      // hasn't explicitly saved it.
      ApiClient.instance.dio.options.baseUrl = previous;
    }
    if (!mounted) return;
    setState(() {
      _testing = false;
      _lastTestOk = ok;
    });
  }

  Future<void> _save() async {
    await ApiClient.instance.setBaseUrl(_controller.text);
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.dns_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Server Connection', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Point LibTrack at your backend. On a physical phone, "localhost" '
            "means the phone itself — use your computer's LAN IP (e.g. "
            'http://192.168.1.5:8080/api/v1) or your deployed domain instead.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Backend base URL',
              hintText: 'http://192.168.1.5:8080/api/v1',
            ),
          ),
          const SizedBox(height: 10),
          if (_lastTestOk != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (_lastTestOk! ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_lastTestOk! ? Icons.check_circle_outline : Icons.error_outline,
                      color: _lastTestOk! ? AppColors.success : AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastTestOk! ? 'Connected successfully.' : 'Could not reach that server. Check the URL and that the backend is running.',
                      style: TextStyle(color: _lastTestOk! ? AppColors.success : AppColors.danger, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering_rounded),
                  label: const Text('Test Connection'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(_saved ? Icons.check : Icons.save_outlined),
                  label: Text(_saved ? 'Saved' : 'Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () async {
                await ApiClient.instance.resetBaseUrlToDefault();
                setState(() => _controller.text = ApiClient.instance.baseUrl);
              },
              child: const Text('Reset to default'),
            ),
          ),
        ],
      ),
    );
  }
}
