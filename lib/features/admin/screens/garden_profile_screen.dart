import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/garden_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/garden_service.dart';
import '../../../core/services/notification_service.dart';
import '../../shared/widgets/main_layout.dart';

class GardenProfileScreen extends StatefulWidget {
  const GardenProfileScreen({super.key});

  @override
  State<GardenProfileScreen> createState() => _GardenProfileScreenState();
}

class _GardenProfileScreenState extends State<GardenProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();
  
  final _gardenService = GardenService();
  final _authService = AuthService();
  bool _isLoading = false;
  GardenModel? _currentGarden;

  @override
  void initState() {
    super.initState();
    _loadGardenInfo();
  }

  Future<void> _loadGardenInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await _gardenService.getGardenInfo();
      if (info != null) {
        setState(() {
          _currentGarden = info;
          _nameController.text = info.name;
          _emailController.text = info.email;
          _phoneController.text = info.phone;
          _addressController.text = info.address;
          _workingHoursController.text = info.workingHours;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      NotificationService.showSnackBar('Utilisateur non connecté', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final garden = GardenModel(
        id: _currentGarden?.id ?? const Uuid().v4(),
        adminId: currentUser.id,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        workingHours: _workingHoursController.text,
      );

      await _gardenService.updateGardenInfo(garden);
      
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 60, color: AppColors.success),
                const SizedBox(height: 16),
                const Text('Profil mis à jour !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Génial'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      NotificationService.showSnackBar('Erreur: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Profil Garderie',
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
                  child: Image.asset(
                    'assets/illustrations/garderie_profile.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations générales',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la garderie',
                          hintText: 'Ex: Les Petits Anges',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'contact@garderie.com',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Adresse',
                          hintText: 'Entrez l\'adresse complète',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _workingHoursController,
                        decoration: const InputDecoration(
                          labelText: 'Heures de travail',
                          hintText: 'Ex: 08:00 - 17:00',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: const Text('Enregistrer les modifications'),
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
