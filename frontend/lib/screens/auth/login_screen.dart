import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../config/app_config.dart';
import '../../widgets/server_config_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false; // Default to Sign In tab
  UserRole _selectedRole = UserRole.elderlyUser;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locationService.requestPermission();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _handleSubmit() async {
    final rawPhone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (_isSignUp && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name.'),
          backgroundColor: AppColors.brandRed,
        ),
      );
      return;
    }

    if (rawPhone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both phone number and password.'),
          backgroundColor: AppColors.brandRed,
        ),
      );
      return;
    }

    if (_isSignUp && password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long.'),
          backgroundColor: AppColors.brandRed,
        ),
      );
      return;
    }

    final formattedPhone = rawPhone.startsWith('+91')
        ? rawPhone
        : '+91${rawPhone.replaceAll(RegExp(r'\D'), '')}';

    final auth = context.read<AuthProvider>();

    try {
      if (_isSignUp) {
        await auth.register(
          displayName: name,
          phone: formattedPhone,
          password: password,
          role: _selectedRole,
          remember: _rememberMe,
        );
      } else {
        await auth.login(
          phone: formattedPhone,
          password: password,
          preferredRole: _selectedRole,
          remember: _rememberMe,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().contains('already exists')
            ? 'This phone number is already registered. Please tap "Sign In".'
            : 'Authentication failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.brandRed,
          ),
        );
      }
    }
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
              // Top Bar: Server Host / Network Config Chip
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await ServerConfigDialog.show(context);
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.dns_outlined, size: 14, color: AppColors.slate600),
                        const SizedBox(width: 5),
                        Text(
                          AppConfig.host.replaceFirst('http://', '').replaceFirst('https://', ''),
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.slate700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.tune, size: 12, color: AppColors.slate500),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

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
              const SizedBox(height: 14),
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

              const SizedBox(height: 24),

              // Mode Toggle (Create Account vs Sign In)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSignUp = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignUp ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSignUp
                                ? [
                                    BoxShadow(
                                      color: AppColors.slate900.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _isSignUp ? FontWeight.bold : FontWeight.w600,
                              color: _isSignUp ? AppColors.slate900 : AppColors.slate500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSignUp = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isSignUp
                                ? [
                                    BoxShadow(
                                      color: AppColors.slate900.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: !_isSignUp ? FontWeight.bold : FontWeight.w600,
                              color: !_isSignUp ? AppColors.slate900 : AppColors.slate500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Step 1: Choose Role
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

              const SizedBox(height: 20),

              // Step 2: Credentials Form
              Text(
                _isSignUp ? '2. ENTER DETAILS & CREDENTIALS' : '2. ENTER LOGIN CREDENTIALS',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              // Name Field (Required for Create Account)
              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Shivam Raj',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.slate500),
                    filled: true,
                    fillColor: AppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.slate300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.slate300),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
                        hintText: '10-digit phone number',
                        hintStyle: TextStyle(color: AppColors.slate400),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: _isSignUp ? 'Password (minimum 8 characters)' : 'Enter password',
                  hintStyle: const TextStyle(color: AppColors.slate400),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.slate400,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Remember Session Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: isElderly ? AppColors.brandRed : AppColors.brandBlue,
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

              const SizedBox(height: 16),

              // Primary Action Button (Create Account or Sign In)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isElderly ? AppColors.brandRed : AppColors.brandBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isSignUp
                              ? 'Create Account & Join Sahaay'
                              : (isElderly
                                  ? 'Sign In as Senior Resident'
                                  : 'Sign In as Community Responder'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // 1-Tap Quick Demo Credentials Section
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
                              setState(() {
                                _isSignUp = false;
                                _selectedRole = UserRole.elderlyUser;
                                _nameController.text = 'Kamla Devi';
                                _phoneController.text = '9876543210';
                                _passwordController.text = 'password123';
                              });
                              _handleSubmit();
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
                              setState(() {
                                _isSignUp = false;
                                _selectedRole = UserRole.volunteer;
                                _nameController.text = 'Rahul Sharma';
                                _phoneController.text = '9876543211';
                                _passwordController.text = 'password123';
                              });
                              _handleSubmit();
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

              const SizedBox(height: 12),

              // Instant Guest Mode Button
              Center(
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final guestName = _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : null;
                        await auth.guestLogin(displayName: guestName);
                      },
                      icon: const Icon(Icons.bolt, color: AppColors.brandRed, size: 20),
                      label: const Text(
                        '⚡ Continue as Guest (Senior Citizen / Victim)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.brandRed,
                        ),
                      ),
                    ),
                    const Text(
                      'Guests can trigger emergency SOS. To receive & view help requests, create or sign in with a Responder account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

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
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : AppColors.slate400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : AppColors.slate700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? activeColor.withOpacity(0.8) : AppColors.slate400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
