import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../shared/widgets/main_layout.dart';
import '../../shared/widgets/search_filter_bar.dart';
import 'photos_list_screen.dart';

class ActivityFoldersScreen extends StatelessWidget {
  final String date;
  final List<ActivityPhoto> photos;

  const ActivityFoldersScreen({
    super.key,
    required this.date,
    this.photos = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Group photos by activity title
    final Map<String, List<ActivityPhoto>> groupedByActivity = {};
    for (var photo in photos) {
      final title = photo.activityTitle ?? 'Sans titre';
      if (!groupedByActivity.containsKey(title)) {
        groupedByActivity[title] = [];
      }
      groupedByActivity[title]!.add(photo);
    }

    final activityNames = groupedByActivity.keys.toList();

    return MainLayout(
      title: 'Activités - $date',
      showBackButton: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: SearchFilterBar(
              hintText: 'Rechercher une activité...',
              onFilterPressed: () {},
            ),
          ),
          Expanded(
            child: activityNames.isEmpty
                ? const Center(
                    child: Text('Aucune photo trouvée pour cette date'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activityNames.length,
                    itemBuilder: (context, index) {
                      final name = activityNames[index];
                      final activityPhotos = groupedByActivity[name]!;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_activity_rounded,
                              color: AppColors.secondary,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${activityPhotos.length} photos',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhotosListScreen(
                                  title: name,
                                  photos: activityPhotos,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
