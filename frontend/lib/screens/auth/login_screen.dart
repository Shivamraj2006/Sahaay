import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.elderlyUser;
  final _phoneController = TextEditingController(text: '9876543210');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      if (role == UserRole.elderlyUser) {
        _phoneController.text = '9876543210';
      } else {
        _phoneController.text = '9876543211';
      }
    });
  }

  Future<void> _handleLogin() async {
    final rawPhone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (rawPhone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both phone number and password.'),
          backgroundColor: AppColors.brandRed,
        ),
      );
      return;
    }

    final formattedPhone = rawPhone.startsWith('+91')
        ? rawPhone
        : '+91$rawPhone';

    final auth = context.read<AuthProvider>();
    await auth.login(
      phone: formattedPhone,
      password: password,
      preferredRole: _selectedRole,
      remember: _rememberMe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isElderly = _selectedRole == UserRole.elderlyUser;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // App Emblem & Welcome Header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isElderly ? AppColors.rose50 : AppColors.brandBlueLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isElderly ? AppColors.brandRedSoft : AppColors.brandBlueBorder,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isElderly ? Icons.emergency : Icons.medical_services_rounded,
                    color: isElderly ? AppColors.brandRed : AppColors.brandBlue,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to Sahaay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slate950,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Community Emergency Response Network',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),

              const SizedBox(height: 28),

              // Step 1: Choose Role (Victim vs Responder)
              const Text(
                '1. SELECT YOUR ACCOUNT TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              // Role Cards Row
              Row(
                children: [
                  // Senior Citizen / Victim Card
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.elderlyUser,
                      icon: Icons.elderly,
                      title: 'Senior Citizen\n(Victim)',
                      subtitle: 'Needs SOS help',
                      activeColor: AppColors.brandRed,
                      activeBg: AppColors.rose50,
                      activeBorder: AppColors.brandRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Responder Card
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.volunteer,
                      icon: Icons.shield,
                      title: 'Community\nResponder',
                      subtitle: 'Available to assist',
                      activeColor: AppColors.brandBlue,
                      activeBg: AppColors.brandBlueLight,
                      activeBorder: AppColors.brandBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Step 2: Credentials Form
              const Text(
                '2. ENTER CREDENTIALS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              // Phone Field with +91 Prefix
              Row(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.slate300),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Enter 10-digit phone',
                        hintStyle: TextStyle(color: AppColors.slate400),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  hintStyle: const TextStyle(color: AppColors.slate400),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.slate500,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Remember me checkbox
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: isElderly ? AppColors.brandRed : AppColors.brandBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? true;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Save session on this device',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Primary Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isElderly ? AppColors.brandRed : AppColors.brandBlue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isElderly
                              ? 'Sign In as Senior Resident'
                              : 'Sign In as Community Responder',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 1-Tap Quick Demo Fill Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ 1-Tap Quick Demo Credentials:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _onRoleChanged(UserRole.elderlyUser);
                              _handleLogin();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.brandRedSoft),
                              backgroundColor: AppColors.rose50,
                            ),
                            child: const Text(
                              'Kamla Devi\n(Amma)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandRed,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _onRoleChanged(UserRole.volunteer);
                              _handleLogin();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.brandBlueBorder),
                              backgroundColor: AppColors.brandBlueLight,
                            ),
                            child: const Text(
                              'Rahul Sharma\n(Responder)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Disclaimer
              const Text(
                'Sahaay connects you to community responders. It complements public services and does not replace 112/108.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.slate400,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color activeColor,
    required Color activeBg,
    required Color activeBorder,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => _onRoleChanged(role),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBorder : AppColors.slate200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: activeColor.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : AppColors.slate400,
                  size: 28,
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? activeColor : AppColors.slate300,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : AppColors.slate800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? activeColor.withOpacity(0.8) : AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
