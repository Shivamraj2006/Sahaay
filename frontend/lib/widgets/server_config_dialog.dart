import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/socket_service.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  Map<String, dynamic>? _testResult;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppConfig.host);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runConnectionTest() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final res = await AppConfig.testConnection(_controller.text.trim());

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = res;
      });
    }
  }

  Future<void> _applyAndSave() async {
    final newUrl = _controller.text.trim();
    if (newUrl.isEmpty) return;

    await AppConfig.setHost(newUrl);

    // Reconnect socket if token is present
    if (mounted) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.token != null) {
        socketService.disconnect();
        socketService.connect(auth.token!);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backend connected to: ${AppConfig.host}'),
          backgroundColor: AppColors.brandBlue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandBlueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dns, color: AppColors.brandBlue, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backend Connection',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                Text(
                  'Connect app across local or remote network',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Endpoint URL:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'http://192.168.1.100:3000 or tunnel URL',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: AppColors.slate50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _controller.clear(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Network Presets:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.slate400,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip('Localhost', 'http://localhost:3000'),
                _buildPresetChip('PC Hotspot', 'http://10.42.0.1:3000'),
                _buildPresetChip('LAN IP', 'http://172.25.97.217:3000'),
              ],
            ),
            const SizedBox(height: 14),

            // Connection Test Button & Status
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _runConnectionTest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  side: const BorderSide(color: AppColors.brandBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: _isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandBlue,
                        ),
                      )
                    : const Icon(Icons.network_ping, size: 18),
                label: Text(
                  _isTesting ? 'Testing Health Endpoint...' : 'Ping /health Endpoint',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!['success'] == true
                      ? const Color(0xFFF0FDF4)
                      : AppColors.rose50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _testResult!['success'] == true
                        ? const Color(0xFF86EFAC)
                        : AppColors.brandRedSoft,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _testResult!['success'] == true
                          ? Icons.check_circle
                          : Icons.error_outline,
                      size: 18,
                      color: _testResult!['success'] == true
                          ? const Color(0xFF16A34A)
                          : AppColors.brandRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _testResult!['success'] == true
                                ? 'Server Reachable! (${_testResult!['latencyMs']}ms)'
                                : 'Connection Failed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _testResult!['success'] == true
                                  ? const Color(0xFF15803D)
                                  : AppColors.brandRedDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _testResult!['success'] == true
                                ? 'DB Connected: ${_testResult!['database']} | Chain: ${_testResult!['blockchain']}'
                                : '${_testResult!['error']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _testResult!['success'] == true
                                  ? const Color(0xFF166534)
                                  : AppColors.brandRedDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.slate500)),
        ),
        ElevatedButton(
          onPressed: _applyAndSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text(
            'Save & Connect',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final isCurrent = _controller.text.trim() == url;
    return ActionChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        color: isCurrent ? AppColors.brandBlue : AppColors.slate700,
      ),
      backgroundColor: isCurrent ? AppColors.brandBlueLight : AppColors.slate100,
      side: BorderSide(
        color: isCurrent ? AppColors.brandBlue : AppColors.slate200,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () {
        setState(() {
          _controller.text = url;
          _testResult = null;
        });
      },
    );
  }
}
