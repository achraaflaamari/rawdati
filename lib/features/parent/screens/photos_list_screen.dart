import 'package:flutter/material.dart';
import '../../shared/widgets/main_layout.dart';
import 'photo_viewer_screen.dart';

class PhotosListScreen extends StatelessWidget {
  final String title;

  const PhotosListScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final List<String> images = List.generate(
      10,
      (index) => 'https://picsum.photos/500/300?random=$index',
    );

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
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PhotoViewerScreen(images: images, initialIndex: index),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(images[index], fit: BoxFit.cover),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildMiniReaction('❤️'),
                        _buildMiniReaction('😊'),
                      ],
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
