import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_config.dart';
import 'core/models/user_profile.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/change_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/parent/screens/parent_navigation_screen.dart';
import 'features/shared/screens/main_navigation_screen.dart';
import 'features/staff/screens/staff_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await Permission.notification.request();

  runApp(const RawdatiApp());
}

class RawdatiApp extends StatelessWidget {
  const RawdatiApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    final profile = await authService.getUserProfile(user.id);
    if (profile == null) {
      // If profile fails, sign out to be safe
      await authService.signOut();
      return const LoginScreen();
    }

    if (profile.mustChangePassword) {
      return const ChangePasswordScreen();
    }

    switch (profile.role) {
      case UserRole.admin:
        return const MainNavigationScreen();
      case UserRole.staff:
        return const StaffNavigationScreen();
      case UserRole.parent:
        return const ParentNavigationScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rawdati',
      scaffoldMessengerKey: NotificationService.messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
             return const LoginScreen();
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }
}
