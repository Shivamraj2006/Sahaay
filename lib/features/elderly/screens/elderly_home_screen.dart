import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/emergency_model.dart';
import '../providers/elderly_emergency_provider.dart';
import '../../../shared/widgets/accessibility_notice_banner.dart';
import '../../../shared/widgets/emergency_hotline_banner.dart';

class ElderlyHomeScreen extends ConsumerStatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  ConsumerState<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends ConsumerState<ElderlyHomeScreen> {
  EmergencyCategory _selectedCategory = EmergencyCategory.medical;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _triggerSos() async {
    final notifier = ref.read(elderlyEmergencyProvider.notifier);
    final success = await notifier.initiateSos(
      category: _selectedCategory,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (success && mounted) {
      context.go('/elderly/active');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final emergencyState = ref.watch(elderlyEmergencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahaay — Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome greeting
              Text(
                'Namaste, ${authState.user?.displayName ?? "Citizen"}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Press SOS below to alert verified local volunteers & medical helpers.',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 16),

              // Compliance Notice Banner
              const AccessibilityNoticeBanner(
                message:
                    'Notice: Sahaay connects you with local community responders. It complements, but does not replace, 112, 108, or official emergency services.',
                backgroundColor: Color(0xFFEFF6FF),
                foregroundColor: Color(0xFF1D4ED8),
                icon: Icons.shield_outlined,
              ),
              const SizedBox(height: 20),

              // Category Selector (Fast, readable radio-cards)
              const Text(
                'Select Emergency Category:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ...EmergencyCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                          width: isSelected ? 2.5 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat == EmergencyCategory.medical
                                ? Icons.medical_services_rounded
                                : cat == EmergencyCategory.fallInjury
                                    ? Icons.personal_injury_rounded
                                    : Icons.local_hospital_rounded,
                            color: isSelected ? const Color(0xFFDC2626) : Colors.blueGrey,
                            size: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.label,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFFB91C1C) : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cat.subtitle,
                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Radio<EmergencyCategory>(
                            value: cat,
                            groupValue: _selectedCategory,
                            activeColor: const Color(0xFFDC2626),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 10),
              // Non-sensitive brief note input
              TextField(
                controller: _notesController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Optional Short Note (e.g., Flat 302, 3rd Floor)',
                  helperText: 'Do not enter confidential health records or passwords.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 20),

              // Dominant Big Touch Target SOS Button (Elderly accessibility principle)
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: ElevatedButton(
                    onPressed: emergencyState.isLoading ? null : _triggerSos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 8,
                      shadowColor: Colors.red.withOpacity(0.5),
                      padding: const EdgeInsets.all(24),
                    ),
                    child: emergencyState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 4)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.touch_app_rounded, size: 54, color: Colors.white),
                              SizedBox(height: 6),
                              Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'TAP TO ALERT',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Helpline fallback banner
              const EmergencyHotlineBanner(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
