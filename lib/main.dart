import 'dart:developer' as developer;

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
    debug: true, // a changer dans la prod
  );

  await Permission.notification.request();

  runApp(const RawdatiApp());
}

class RawdatiApp extends StatefulWidget {
  const RawdatiApp({super.key});

  @override
  State<RawdatiApp> createState() => _RawdatiAppState();
}

class _RawdatiAppState extends State<RawdatiApp> {
  final AuthService _authService = AuthService();
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _handleAuthChanges();
  }

  void _handleAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _handleSession(data.session, data.event);
    });
  }

  Future<void> _handleSession(
    Session? session, [
    AuthChangeEvent? event,
  ]) async {
    developer.log('Auth event: $event, session: ${session != null}');

    if (session == null) {
      if (mounted) setState(() => _initialScreen = const LoginScreen());
      return;
    }

    try {
      final profile = await _authService.getUserProfile(session.user.id);
      developer.log('Profile fetched: ${profile?.role}');

      if (profile == null) {
        await _authService.signOut();
        if (mounted) setState(() => _initialScreen = const LoginScreen());
        return;
      }

      if (profile.isBlocked) {
        await _authService.signOut();
        NotificationService.showSnackBar(
          'Votre compte est bloqué. Veuillez contacter l\'administration.',
          isError: true,
        );
        if (mounted) setState(() => _initialScreen = const LoginScreen());
        return;
      }

      if (profile.mustChangePassword && profile.role != UserRole.admin) {
        if (mounted) {
          setState(() => _initialScreen = const ChangePasswordScreen());
        }
        return;
      }

      if (mounted) {
        setState(() {
          switch (profile.role) {
            case UserRole.admin:
              _initialScreen = const MainNavigationScreen();
              break;
            case UserRole.staff:
              _initialScreen = const StaffNavigationScreen();
              break;
            case UserRole.parent:
              _initialScreen = const ParentNavigationScreen();
              break;
          }
        });
      }
    } catch (e) {
      // In case of error fetching profile, don't leave user stuck
      if (mounted) setState(() => _initialScreen = const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rawdati',
      scaffoldMessengerKey: NotificationService.messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home:
          _initialScreen ??
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
