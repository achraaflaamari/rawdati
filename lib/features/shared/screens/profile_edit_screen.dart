import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../widgets/main_layout.dart';

enum EditType { email, password, profile, phone }

class ProfileEditScreen extends StatefulWidget {
  final EditType editType;
  final String? initialValue;

  const ProfileEditScreen({
    super.key,
    required this.editType,
    this.initialValue,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _oldPasswordController = TextEditingController();
  final _newValueController = TextEditingController();
  final _confirmValueController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editType != EditType.password) {
      _newValueController.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newValueController.dispose();
    _confirmValueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPassword = _oldPasswordController.text;
    final newValue = _newValueController.text.trim();
    final confirmValue = _confirmValueController.text.trim();

    if (oldPassword.isEmpty) {
      NotificationService.showSnackBar(
        'Veuillez entrer votre mot de passe actuel pour confirmer',
        isError: true,
      );
      return;
    }

    if (widget.editType == EditType.password) {
      if (newValue.length < 6) {
        NotificationService.showSnackBar(
          'Le nouveau mot de passe doit contenir au moins 6 caractères',
          isError: true,
        );
        return;
      }
      if (newValue != confirmValue) {
        NotificationService.showSnackBar(
          'Les nouveaux mots de passe ne correspondent pas',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Re-authenticate user to verify old password
      final email = _authService.currentUser?.email;
      if (email == null) throw Exception('Utilisateur non trouvé');

      await _authService.signIn(email: email, password: oldPassword);

      // If re-auth successful, proceed with update
      if (widget.editType == EditType.email) {
        await _authService.updateEmail(newValue);
      } else if (widget.editType == EditType.password) {
        await _authService.updatePassword(newValue);
      } else if (widget.editType == EditType.phone) {
        final userId = _authService.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'phone': newValue})
              .eq('id', userId);
        }
      } else if (widget.editType == EditType.profile) {
        final userId = _authService.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'full_name': newValue})
              .eq('id', userId);
        }
      }

      NotificationService.showSnackBar('Mise à jour réussie');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      NotificationService.showSnackBar(
        'Erreur: Mot de passe incorrect ou erreur réseau',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String label;
    IconData icon;
    bool isPassword = false;

    switch (widget.editType) {
      case EditType.email:
        title = 'Changer l\'email';
        label = 'Nouvel Email';
        icon = Icons.email_outlined;
        break;
      case EditType.password:
        title = 'Changer le mot de passe';
        label = 'Nouveau mot de passe';
        icon = Icons.lock_rounded;
        isPassword = true;
        break;
      case EditType.profile:
        title = 'Modifier le profil';
        label = 'Nom complet';
        icon = Icons.person_outline_rounded;
        break;
      case EditType.phone:
        title = 'Changer le téléphone';
        label = 'Nouveau numéro';
        icon = Icons.phone_outlined;
        break;
    }

    return MainLayout(
      title: title,
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirmation requise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pour des raisons de sécurité, veuillez confirmer votre identité avec votre mot de passe actuel.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            TextField(
              controller: _newValueController,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
              ),
              obscureText: isPassword,
              keyboardType: widget.editType == EditType.email
                  ? TextInputType.emailAddress
                  : widget.editType == EditType.phone
                  ? TextInputType.phone
                  : TextInputType.text,
            ),
            if (isPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmValueController,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enregistrer les modifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
