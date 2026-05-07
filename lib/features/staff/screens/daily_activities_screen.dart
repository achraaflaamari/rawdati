import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../shared/widgets/main_layout.dart';
import '../../shared/widgets/search_filter_bar.dart';
import 'activity_detail_screen.dart';

class DailyActivitiesScreen extends StatefulWidget {
  final DateTime date;
  final List<Activity> activities;

  const DailyActivitiesScreen({
    super.key,
    required this.date,
    required this.activities,
  });

  @override
  State<DailyActivitiesScreen> createState() => _DailyActivitiesScreenState();
}

class _DailyActivitiesScreenState extends State<DailyActivitiesScreen> {
  late List<Activity> _filteredActivities;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredActivities = widget.activities;
    _searchController.addListener(_filterActivities);
  }

  void _filterActivities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredActivities = widget.activities.where((activity) {
        return activity.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = DateFormat('dd-MM-yyyy').format(widget.date);

    return MainLayout(
      title: displayDate,
      showBackButton: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: SearchFilterBar(
              controller: _searchController,
              hintText: 'Rechercher une activité...',
              onFilterPressed: () => _showFilterBottomSheet(context),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24.0),
              itemCount: _filteredActivities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final activity = _filteredActivities[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActivityDetailScreen(activity: activity),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_activity_rounded,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                activity.category ?? 'Général',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par type',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Toutes les activités'),
              trailing: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
              ),
              onTap: () => Navigator.pop(context),
            ),
            // ... more filters
          ],
        ),
      ),
    );
  }
}
