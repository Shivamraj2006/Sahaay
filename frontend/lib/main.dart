import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/emergency_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/elderly/elderly_home_screen.dart';
import 'config/app_config.dart';
import 'screens/responder/responder_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadSavedHost();
  runApp(const SahaayApp());
}

class SahaayApp extends StatelessWidget {
  const SahaayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MaterialApp(
        title: 'Sahaay — Senior SOS Emergency Network',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SahaayRootWrapper(),
      ),
    );
  }
}

class SahaayRootWrapper extends StatelessWidget {
  const SahaayRootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    Widget activeScreen;
    if (!auth.isInitialized) {
      activeScreen = const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandRed),
        ),
      );
    } else if (!auth.isAuthenticated) {
      activeScreen = const LoginScreen();
    } else if (auth.isElderly) {
      activeScreen = const ElderlyHomeScreen();
    } else {
      activeScreen = const ResponderHomeScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // If viewing on desktop or wide tablet screen, present within mobile device frame (Stitch Preview)
        if (constraints.maxWidth > 500 && constraints.maxHeight >= 850) {
          final frameHeight = constraints.maxHeight.clamp(720.0, 880.0);
          return Scaffold(
            backgroundColor: AppColors.slate100,
            body: Center(
              child: Container(
                width: 420,
                height: frameHeight,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(44),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate900.withOpacity(0.18),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                  border: Border.all(color: AppColors.slate200, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Simulated iOS status bar & dynamic notch
                    Container(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 24,
                        right: 24,
                        bottom: 4,
                      ),
                      color: AppColors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '9:41',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.slate900,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.signal_cellular_alt, size: 14),
                              SizedBox(width: 4),
                              Icon(Icons.wifi, size: 14),
                              SizedBox(width: 4),
                              Icon(Icons.battery_full, size: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: activeScreen),
                  ],
                ),
              ),
            ),
          );
        }

        // Direct native mobile screen
        return activeScreen;
      },
    );
  }
}
