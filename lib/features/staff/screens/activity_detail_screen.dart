import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/main_layout.dart';
import 'assign_children_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityName;

  const ActivityDetailScreen({super.key, required this.activityName});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final List<String> _photos = [];
  bool _isUploading = false;

  void _uploadPhotos() {
    setState(() {
      _isUploading = true;
    });
    // Simulate upload
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _photos.addAll([
            'https://picsum.photos/200/200?random=1',
            'https://picsum.photos/200/200?random=2',
            'https://picsum.photos/200/200?random=3',
            'https://picsum.photos/200/200?random=4',
            'https://picsum.photos/200/200?random=5',
            'https://picsum.photos/200/200?random=6',
          ]);
          _isUploading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: widget.activityName,
      showBackButton: true,
      child: Column(
        children: [
          Expanded(
            child: _photos.isEmpty ? _buildEmptyState() : _buildPhotoGrid(),
          ),
          if (_photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignChildrenScreen(
                        photos: _photos,
                        activityName: widget.activityName,
                      ),
                    ),
                  );
                },
                child: const Text('Assigner des enfants'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune photo dans cet album',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Commencez par ajouter des photos de l\'activité.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            if (_isUploading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _uploadPhotos,
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Uploader des photos'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 56),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _photos.length + 1,
      itemBuilder: (context, index) {
        if (index == _photos.length) {
          return GestureDetector(
            onTap: _uploadPhotos,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(_photos[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
