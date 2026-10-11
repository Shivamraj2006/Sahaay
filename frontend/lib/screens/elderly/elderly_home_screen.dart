import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/emergency.dart';
import '../../models/user.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/sos_pulse_button.dart';
import '../../widgets/contact_card.dart';
import '../../widgets/contact_options_sheet.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'sos_countdown_dialog.dart';
import 'sos_sent_screen.dart';
import 'contacts_screen.dart';
import 'add_contact_dialog.dart';
import '../shared/history_screen.dart';
import '../shared/settings_screen.dart';

class ElderlyHomeScreen extends StatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  State<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends State<ElderlyHomeScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locationService.requestPermission();
    });
  }

  void _triggerSos(BuildContext context, EmergencyCategory category) {
    final emergencyProvider = context.read<EmergencyProvider>();

    emergencyProvider.startCountdown(
      category: category,
      onComplete: () {
        // Countdown completed, navigate to SOS Sent screen
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Dismiss dialog
          setState(() {
            // Stay on sent view
          });
        }
      },
    );

    // Show Countdown Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Consumer<EmergencyProvider>(
          builder: (context, provider, _) {
            return SosCountdownDialog(
              seconds: provider.countdownSeconds,
              onCancel: () {
                provider.cancelCountdown();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('SOS alert was canceled.'),
                    backgroundColor: AppColors.slate900,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();

    // If an emergency is currently active or sent, show the SOS Sent screen
    if (emergencyProvider.hasActiveEmergency) {
      return SosSentScreen(
        onDismiss: () {
          emergencyProvider.reset();
        },
      );
    }

    Widget currentBody;
    switch (_currentTabIndex) {
      case 0:
        currentBody = _buildHomeContent(context);
        break;
      case 1:
        currentBody = ContactsScreen(
          onBack: () => setState(() => _currentTabIndex = 0),
        );
        break;
      case 2:
        currentBody = const HistoryScreen();
        break;
      case 3:
        currentBody = const SettingsScreen();
        break;
      default:
        currentBody = _buildHomeContent(context);
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: currentBody,
      bottomNavigationBar: SahaayBottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final contacts = contactsProvider.contacts;
    final user = context.watch<AuthProvider>().user;
    final greetingName = (user?.displayName.isNotEmpty == true)
        ? '${user!.displayName} 👋'
        : 'Welcome 👋';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with greeting and avatar (Stitch Screen 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good morning,',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        greetingName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "We're here for you.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Dynamic User Avatar with green online dot
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.brandSuccess, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: (user?.displayName.toLowerCase().contains('amma') == true ||
                                user?.displayName.toLowerCase().contains('kamla') == true)
                            ? Image.asset(
                                'assets/images/amma.jpg',
                                width: 58,
                                height: 58,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.slate200,
                                  alignment: Alignment.center,
                                  child: Text(
                                    user?.displayName.isNotEmpty == true
                                        ? user!.displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.rose50,
                                alignment: Alignment.center,
                                child: Text(
                                  user?.displayName.isNotEmpty == true
                                      ? user!.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppColors.brandRed,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: AppColors.brandSuccess,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Mode Banner & Role Switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: user?.isGuest == true ? AppColors.rose50 : AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: user?.isGuest == true ? AppColors.brandRedSoft : AppColors.slate200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    user?.isGuest == true ? Icons.bolt : Icons.elderly,
                    color: AppColors.brandRed,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user?.isGuest == true
                          ? 'Guest Mode (Victim) — Press SOS to alert network'
                          : 'Senior Citizen Mode — Emergency SOS enabled',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate800,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      context.read<AuthProvider>().switchRole(UserRole.volunteer);
                    },
                    child: const Text(
                      'Responder ➔',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Live Location Status Banner
            ListenableBuilder(
              listenable: locationService,
              builder: (context, _) {
                final hasGps = locationService.state == LocationState.active;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasGps ? AppColors.brandSuccessLight : AppColors.amber50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasGps ? AppColors.brandSuccess : AppColors.amber200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasGps ? Icons.location_on : Icons.location_searching,
                        color: hasGps ? AppColors.brandSuccess : AppColors.amber700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationService.statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasGps ? AppColors.brandSuccess : AppColors.amber900,
                          ),
                        ),
                      ),
                      if (!hasGps)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => locationService.requestPermission(),
                          child: const Text(
                            'Grant GPS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Central Pulsing Big Red SOS Button (Stitch Screen 1)
            Center(
              child: SosPulseButton(
                onTap: () => _triggerSos(context, EmergencyCategory.medical),
              ),
            ),

            const SizedBox(height: 32),

            // Emergency Contacts Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${contacts.length} people notified upon SOS alert',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddContactDialog(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlueLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.brandBlueBorder,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.brandBlue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Emergency Contact Cards
            if (contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'No emergency contacts yet.\nTap "Add" above to add family or caregivers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate500,
                    height: 1.4,
                  ),
                ),
              )
            else
              ...contacts.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ContactCard(
                    contact: c,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => ContactOptionsSheet(
                          contact: c,
                          onRemove: () {
                            contactsProvider.removeContact(c.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${c.name} removed from priority contacts',
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.slate900,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
