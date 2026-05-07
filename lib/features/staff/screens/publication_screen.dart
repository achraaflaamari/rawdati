import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../../core/services/staff_service.dart';
import '../../shared/widgets/main_layout.dart';

class PublicationScreen extends StatefulWidget {
  final Activity activity;
  final List<File> imageFiles;
  final Map<int, List<String>> assignments;

  const PublicationScreen({
    super.key,
    required this.activity,
    required this.imageFiles,
    required this.assignments,
  });

  @override
  State<PublicationScreen> createState() => _PublicationScreenState();
}

class _PublicationScreenState extends State<PublicationScreen> {
  final _staffService = StaffService();
  bool _isUploading = false;
  double _progress = 0.0;
  String _uploadStatus = 'Prêt pour la publication';

  Future<void> _startFinalPublication() async {
    setState(() {
      _isUploading = true;
      _progress = 0.0;
      _uploadStatus = 'Initialisation...';
    });

    try {
      final totalSteps = widget.imageFiles.length;

      for (int i = 0; i < widget.imageFiles.length; i++) {
        final file = widget.imageFiles[i];
        final childIds = widget.assignments[i] ?? [];

        setState(() {
          _uploadStatus = 'Upload photo ${i + 1}/$totalSteps...';
        });

        // 1. Upload file to storage
        final photoUrl = await _staffService.uploadPhoto(file);

        // 2. Create photo entry in DB
        final response = await Supabase.instance.client
            .from('activity_photos')
            .insert({'activity_id': widget.activity.id, 'photo_url': photoUrl})
            .select()
            .single();

        final photoId = response['id'];

        // 3. Create assignments
        if (childIds.isNotEmpty) {
          setState(() {
            _uploadStatus = 'Assignation photo ${i + 1}/$totalSteps...';
          });
          await _staffService.assignChildrenToPhoto(photoId, childIds);
        }

        setState(() {
          _progress = (i + 1) / totalSteps;
        });
      }

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _uploadStatus = 'Publication terminée !';
        });
        _showSuccessBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = 'Erreur lors de la publication';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la publication: $e')),
        );
      }
    }
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.secondary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Félicitations !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vos photos ont été publiées avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Retour à l\'accueil'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniqueChildren = widget.assignments.values
        .expand((e) => e)
        .toSet()
        .length;

    return MainLayout(
      title: 'Publication',
      showBackButton: true,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé de la publication',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryItem(
                    Icons.folder_open_rounded,
                    'Activité',
                    widget.activity.title,
                  ),
                  const Divider(height: 32),
                  _buildSummaryItem(
                    Icons.photo_library_outlined,
                    'Photos',
                    '${widget.imageFiles.length} photos à uploader',
                  ),
                  const Divider(height: 32),
                  _buildSummaryItem(
                    Icons.people_outline_rounded,
                    'Enfants',
                    '$uniqueChildren enfants concernés',
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_isUploading) ...[
              Center(
                child: Text(
                  _uploadStatus,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                color: AppColors.primary,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startFinalPublication,
                child: const Text('Publier maintenant'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
