import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/child_model.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/notification_service.dart';
import '../../shared/widgets/main_layout.dart';

class ChildFormScreen extends StatefulWidget {
  final ChildModel? child;

  const ChildFormScreen({super.key, this.child});

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _groupController = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _isLoading = false;
  final _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _firstNameController.text = widget.child!.firstName;
      _lastNameController.text = widget.child!.lastName;
      _groupController.text = widget.child!.group;
      _selectedBirthDate = widget.child!.birthDate;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2020),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveChild() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _groupController.text.isEmpty ||
        _selectedBirthDate == null) {
      NotificationService.showSnackBar('Veuillez remplir tous les champs', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final child = ChildModel(
        id: widget.child?.id ?? const Uuid().v4(),
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        group: _groupController.text,
        birthDate: _selectedBirthDate!,
        parentIds: widget.child?.parentIds ?? [],
      );

      if (widget.child == null) {
        await _adminService.addChild(child);
        NotificationService.showSnackBar('Enfant ajouté avec succès');
      } else {
        await _adminService.updateChild(child);
        NotificationService.showSnackBar('Enfant mis à jour avec succès');
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
    final bool isEditing = widget.child != null;

    return MainLayout(
      title: isEditing ? 'Modifier Enfant' : 'Nouveau Enfant',
      showBackButton: true,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/illustrations/Enfant_admin_banner.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            size: 40,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          hintText: 'Entrez le prénom',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          hintText: 'Entrez le nom',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _groupController,
                        decoration: const InputDecoration(
                          labelText: 'Groupe / Section',
                          hintText: 'Ex: Petite Section A',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: TextEditingController(
                              text: _selectedBirthDate == null
                                  ? ''
                                  : DateFormat('dd/MM/yyyy').format(_selectedBirthDate!),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Date de naissance',
                              hintText: 'Choisir une date',
                              suffixIcon: Icon(Icons.calendar_today_rounded),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveChild,
                        child: Text(
                          isEditing ? 'Mettre à jour' : 'Ajouter l\'enfant',
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
