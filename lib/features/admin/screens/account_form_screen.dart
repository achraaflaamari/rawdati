import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../shared/widgets/main_layout.dart';

class AccountFormScreen extends StatefulWidget {
  final String role; // 'Staff' or 'Parent'
  final UserProfile? userProfile;

  const AccountFormScreen({
    super.key,
    required this.role,
    this.userProfile,
  });

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _authService = AuthService();
  final _adminService = AdminService();
  
  bool _isLoading = false;
  List<ChildModel> _allChildren = [];
  final List<String> _selectedChildIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.userProfile != null) {
      _fullNameController.text = widget.userProfile!.fullName ?? '';
      _emailController.text = widget.userProfile!.email;
      _phoneController.text = widget.userProfile!.phone ?? '';
      _addressController.text = widget.userProfile!.address ?? '';
    }
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final children = await _adminService.getChildren();
      setState(() {
        _allChildren = children;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _generatePassword() {
    setState(() {
      _passwordController.text = _authService.generateRandomPassword();
    });
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _fullNameController.text.isEmpty) {
      NotificationService.showSnackBar('Email et Nom sont requis', isError: true);
      return;
    }

    if (widget.userProfile == null && _passwordController.text.isEmpty) {
      NotificationService.showSnackBar('Mot de passe requis pour un nouveau compte', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.userProfile == null) {
        // Create new account
        await _authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          role: widget.role == 'Staff' ? UserRole.staff : UserRole.parent,
          fullName: _fullNameController.text,
          phone: _phoneController.text,
          address: widget.role == 'Parent' ? _addressController.text : null,
        );
        // Note: In a real app, we'd also handle the association of children in Supabase
        NotificationService.showSnackBar('Invitation envoyée avec succès');
      } else {
        // Update existing profile (not implemented in AuthService yet, but could be)
        NotificationService.showSnackBar('Mise à jour réussie (Simulation)');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      NotificationService.showSnackBar('Erreur: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.userProfile != null;
    final bannerAsset = widget.role == 'Staff'
        ? 'assets/illustrations/staff_banner_admin.jpg'
        : 'assets/illustrations/parent_banner_admin.jpg';

    return MainLayout(
      title: isEdit ? 'Modifier ${widget.role}' : 'Invitation ${widget.role}',
      showBackButton: true,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.asset(bannerAsset, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit
                            ? 'Modifier les informations'
                            : 'Inviter un nouveau membre',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEdit
                            ? 'Mettez à jour les détails du compte.'
                            : 'Un compte sera créé avec le mot de passe spécifié.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet',
                          hintText: 'Entrez le nom',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'adresse@email.com',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        readOnly: isEdit,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          hintText: '+216 -- --- ---',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      if (widget.role == 'Parent') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse',
                            hintText: 'Adresse domicile',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enfants associés',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _allChildren.map((child) {
                            final isSelected = _selectedChildIds.contains(child.id);
                            return FilterChip(
                              label: Text(child.fullName),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedChildIds.add(child.id);
                                  } else {
                                    _selectedChildIds.remove(child.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      if (!isEdit) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Mot de passe initial',
                                  hintText: 'Générer ou saisir',
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _generatePassword,
                              icon: const Icon(Icons.refresh, color: AppColors.primary),
                              tooltip: 'Générer',
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: Text(
                          isEdit ? 'Enregistrer' : 'Envoyer l\'invitation',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
