import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/providers/auth_provider.dart';

class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends ConsumerState<AdminVerificationScreen> {
  bool _isLoading = false;
  List<dynamic> _pendingResponders = [];
  String? _message;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get('/admin/responders/pending');
      setState(() {
        _pendingResponders = res is List ? res : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Failed to load pending responders: $e';
      });
    }
  }

  Future<void> _verifyResponder(String id) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/admin/responders/$id/verify');
      setState(() => _message = 'Responder verified successfully.');
      _fetchPending();
    } catch (e) {
      setState(() => _message = 'Action failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin / Verifier Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPending,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Responder Verification Queue',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verifiers confirm credentials before responders can receive community SOS alerts.',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              if (_message != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_message!, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _pendingResponders.isEmpty
                        ? const Center(child: Text('No pending responder applications.'))
                        : ListView.builder(
                            itemCount: _pendingResponders.length,
                            itemBuilder: (ctx, idx) {
                              final item = _pendingResponders[idx];
                              final id = item['id'] ?? item['_id'];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.person_pin)),
                                  title: Text(item['displayName'] ?? 'Applicant', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Role: ${item['requestedRole'] ?? item['role']} • Phone: ${item['phone']}'),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(90, 36),
                                    ),
                                    onPressed: () => _verifyResponder(id),
                                    child: const Text('Verify'),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
