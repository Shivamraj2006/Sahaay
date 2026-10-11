import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final _phoneController = TextEditingController(text: '+919876543210');
  final _passwordController = TextEditingController(text: 'demo1234');
  final _nameController = TextEditingController(text: 'Dada Ramkrishna');
  UserRole _selectedRole = UserRole.elderlyUser;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _fillPreset(String name, String phone, UserRole role) {
    setState(() {
      _nameController.text = name;
      _phoneController.text = phone;
      _selectedRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Emblem
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sahaay — सहाय',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Community Emergency Response Network for Elders',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey, height: 1.3),
                  ),
                  const SizedBox(height: 24),

                  // Demo Quick-Fill Buttons
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ Hackathon Demo Quick-Profiles:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              label: const Text('Elderly (Ramkrishna)'),
                              avatar: const Icon(Icons.elderly, size: 16),
                              onPressed: () => _fillPreset('Dada Ramkrishna', '+919876543210', UserRole.elderlyUser),
                            ),
                            ActionChip(
                              label: const Text('Volunteer (Aarav)'),
                              avatar: const Icon(Icons.volunteer_activism, size: 16),
                              onPressed: () => _fillPreset('Aarav Sharma', '+919876543211', UserRole.volunteer),
                            ),
                            ActionChip(
                              label: const Text('Doctor (Dr. Sneha)'),
                              avatar: const Icon(Icons.medical_services, size: 16),
                              onPressed: () => _fillPreset('Dr. Sneha Sen', '+919876543212', UserRole.medicalProfessional),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold))),
                          selected: !_isSignUp,
                          onSelected: (val) => setState(() => _isSignUp = !val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Register', style: TextStyle(fontWeight: FontWeight.bold))),
                          selected: _isSignUp,
                          onSelected: (val) => setState(() => _isSignUp = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Error message banner
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Fields
                  if (_isSignUp) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role Selection',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        UserRole.elderlyUser,
                        UserRole.volunteer,
                        UserRole.medicalProfessional,
                      ].map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.label, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (+91XXXXXXXXXX)',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            final notifier = ref.read(authNotifierProvider.notifier);
                            bool success;
                            if (_isSignUp) {
                              success = await notifier.register(
                                displayName: _nameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                password: _passwordController.text.trim(),
                                requestedRole: _selectedRole.value,
                              );
                            } else {
                              success = await notifier.login(
                                _phoneController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            }

                            if (success && mounted) {
                              final user = ref.read(authNotifierProvider).user;
                              if (user?.role.isResponder == true) {
                                context.go('/responder');
                              } else {
                                context.go('/elderly');
                              }
                            }
                          },
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(_isSignUp ? 'Create Sahaay Account' : 'Secure Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
