import 'package:flutter/material.dart';
import '../../../core/models/activity.dart';
import '../../shared/widgets/main_layout.dart';
import 'photo_viewer_screen.dart';

class PhotosListScreen extends StatelessWidget {
  final String title;
  final List<ActivityPhoto> photos;

  const PhotosListScreen({
    super.key,
    required this.title,
    this.photos = const [],
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: title,
      showBackButton: true,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PhotoViewerScreen(photos: photos, initialIndex: index),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'photo_${photo.id}',
                    child: Image.network(photo.photoUrl, fit: BoxFit.cover),
                  ),
                  if (photo.reactions.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Row(
                        children: photo.reactions.keys.take(2).map((emoji) {
                          return _buildMiniReaction(emoji);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniReaction(String emoji) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }
}
