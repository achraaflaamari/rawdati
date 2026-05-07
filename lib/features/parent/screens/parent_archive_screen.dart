import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../../core/services/parent_service.dart';
import '../../shared/widgets/main_layout.dart';
import '../../shared/widgets/search_filter_bar.dart';
import 'activity_folders_screen.dart';

class ParentArchiveScreen extends StatefulWidget {
  const ParentArchiveScreen({super.key});

  @override
  State<ParentArchiveScreen> createState() => _ParentArchiveScreenState();
}

class _ParentArchiveScreenState extends State<ParentArchiveScreen> {
  final _parentService = ParentService();
  List<ActivityPhoto> _allPhotos = [];
  Map<String, List<ActivityPhoto>> _groupedPhotos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final photos = await _parentService.getParentFeed();
      final Map<String, List<ActivityPhoto>> groups = {};

      for (var photo in photos) {
        if (photo.activityDate != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(photo.activityDate!);
          if (!groups.containsKey(dateKey)) {
            groups[dateKey] = [];
          }
          groups[dateKey]!.add(photo);
        }
      }

      setState(() {
        _allPhotos = photos;
        _groupedPhotos = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = _groupedPhotos.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return MainLayout(
      title: 'Archive',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: SearchFilterBar(
                    hintText: 'Rechercher une date...',
                    onFilterPressed: () {},
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedDates[index];
                        final photos = _groupedPhotos[dateKey]!;
                        final displayDate = DateFormat(
                          'dd-MM-yyyy',
                        ).format(DateTime.parse(dateKey));

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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.folder_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              displayDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${photos.length} photos',
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
                                  builder: (context) => ActivityFoldersScreen(
                                    date: displayDate,
                                    photos: photos,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
