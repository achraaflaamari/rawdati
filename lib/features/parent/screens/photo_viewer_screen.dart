import 'package:flutter/material.dart';
import '../../../core/models/activity.dart';
import '../../../core/services/parent_service.dart';
import '../../../core/services/notification_service.dart';
// Note: For real download, you'd use path_provider and dio or similar
// For this prototype, I will simulate the download logic

class PhotoViewerScreen extends StatefulWidget {
  final List<ActivityPhoto> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final _parentService = ParentService();
  final List<String> _reactions = ['❤️', '😊', '😂', '😮', '👏'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleReaction(String emoji) async {
    final photo = widget.photos[_currentIndex];
    try {
      if (photo.myReaction == emoji) {
        await _parentService.removeReaction(photo.id);
      } else {
        await _parentService.reactToPhoto(photo.id, emoji);
      }
      // In a real app, you'd update local state or re-fetch
      setState(() {
        // Simple local update for UX
        // photo.myReaction = (photo.myReaction == emoji) ? null : emoji;
      });
      NotificationService.showSnackBar('Réaction mise à jour');
    } catch (e) {
      NotificationService.showSnackBar(
        'Erreur lors de la réaction',
        isError: true,
      );
    }
  }

  Future<void> _downloadPhoto() async {
    NotificationService.showSnackBar('Téléchargement commencé...');
    // Simulate delay
    await Future.delayed(const Duration(seconds: 2));
    NotificationService.showSnackBar('Photo enregistrée dans la galerie');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Hero(
                tag: 'photo_${widget.photos[index].id}',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.photos[index].photoUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),

          // Header
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        widget.photos[_currentIndex].activityTitle ??
                            'Activité',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${widget.photos.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _downloadPhoto,
                  ),
                ],
              ),
            ),
          ),

          // Navigation Arrows
          if (_currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white54,
                    size: 48,
                  ),
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          if (_currentIndex < widget.photos.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white54,
                    size: 48,
                  ),
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),

          // Bottom Bar for Reactions
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _reactions
                    .map((emoji) => _buildReactionItem(emoji))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionItem(String emoji) {
    final isSelected = widget.photos[_currentIndex].myReaction == emoji;
    return GestureDetector(
      onTap: () => _handleReaction(emoji),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(emoji, style: TextStyle(fontSize: isSelected ? 30 : 24)),
      ),
    );
  }
}
