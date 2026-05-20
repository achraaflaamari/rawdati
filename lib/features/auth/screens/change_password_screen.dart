import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../parent/screens/parent_navigation_screen.dart';
import '../../shared/screens/main_navigation_screen.dart';
import '../../staff/screens/staff_navigation_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_passwordController.text.length < 6) {
      NotificationService.showSnackBar(
        'Le mot de passe doit contenir au moins 6 caractères',
        isError: true,
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      NotificationService.showSnackBar(
        'Les mots de passe ne correspondent pas',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.updatePassword(_passwordController.text);
      NotificationService.showSnackBar('Mot de passe mis à jour avec succès');
      
      // Wait a moment to ensure database update is complete
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        // Get the updated profile to verify password change was recorded
        final user = _authService.currentUser;
        if (user != null) {
          final profile = await _authService.getUserProfile(user.id);
          if (profile != null && mounted) {
            // Verify that must_change_password is now false
            if (profile.mustChangePassword) {
              developer.log('Warning: must_change_password still true, retrying...');
              // Retry the update once more
              await Future.delayed(const Duration(milliseconds: 500));
              await _authService.updatePassword(_passwordController.text);
            }
            
            Widget nextScreen;
            switch (profile.role) {
              case UserRole.admin:
                nextScreen = const MainNavigationScreen();
                break;
              case UserRole.staff:
                nextScreen = const StaffNavigationScreen();
                break;
              case UserRole.parent:
                nextScreen = const ParentNavigationScreen();
                break;
            }
            
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => nextScreen),
                (route) => false,
              );
            }
          }
        }
      }
    } catch (e) {
      developer.log('Password update error: $e');
      NotificationService.showSnackBar('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Nouveau Mot de Passe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pour votre sécurité, veuillez changer votre mot de passe lors de votre première connexion.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Mettre à jour le mot de passe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
