import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/screens/admin_verification_screen.dart';
import 'features/auth/models/user_model.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/elderly/screens/elderly_active_emergency_screen.dart';
import 'features/elderly/screens/elderly_home_screen.dart';
import 'features/responder/screens/responder_active_emergency_screen.dart';
import 'features/responder/screens/responder_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SahaayApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/auth';
      }

      final user = authState.user;
      final role = user?.role ?? UserRole.elderlyUser;

      // Role-based route protection
      if (isAuthRoute) {
        if (role.isAdminOrVerifier) return '/admin';
        if (role.isResponder) return '/responder';
        return '/elderly';
      }

      // Prevent unauthorized cross-role access
      if (state.matchedLocation.startsWith('/admin') && !role.isAdminOrVerifier) {
        return role.isResponder ? '/responder' : '/elderly';
      }
      if (state.matchedLocation.startsWith('/responder') && !role.isResponder && !role.isAdminOrVerifier) {
        return '/elderly';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      // Elderly routes
      GoRoute(
        path: '/elderly',
        builder: (context, state) => const ElderlyHomeScreen(),
        routes: [
          GoRoute(
            path: 'active',
            builder: (context, state) => const ElderlyActiveEmergencyScreen(),
          ),
        ],
      ),
      // Responder routes
      GoRoute(
        path: '/responder',
        builder: (context, state) => const ResponderHomeScreen(),
        routes: [
          GoRoute(
            path: 'active',
            builder: (context, state) => const ResponderActiveEmergencyScreen(),
          ),
        ],
      ),
      // Admin / Verifier routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminVerificationScreen(),
      ),
    ],
  );
});

class SahaayApp extends ConsumerWidget {
  const SahaayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sahaay — Elderly Emergency Network',
      theme: SahaayTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
