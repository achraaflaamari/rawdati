import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../../core/services/staff_service.dart';
import '../../shared/widgets/main_layout.dart';
import '../../shared/widgets/search_filter_bar.dart';
import 'daily_activities_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final _staffService = StaffService();
  Map<String, List<Activity>> _allGroupedActivities = {};
  Map<String, List<Activity>> _filteredGroupedActivities = {};
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredGroupedActivities = Map.from(_allGroupedActivities);
      });
      return;
    }

    final Map<String, List<Activity>> filtered = {};
    _allGroupedActivities.forEach((dateStr, activities) {
      final date = DateTime.parse(dateStr);
      final displayDate = DateFormat('dd-MM-yyyy').format(date);
      if (displayDate.contains(query)) {
        filtered[dateStr] = activities;
      }
    });

    setState(() {
      _filteredGroupedActivities = filtered;
    });
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _staffService.getAllActivities();
      final Map<String, List<Activity>> grouped = {};
      
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      for (var activity in activities) {
        final dateStr = DateFormat('yyyy-MM-dd').format(activity.activityDate);
        
        // Skip today's activities in the list (already shown in dashboard)
        if (dateStr == todayStr) continue;

        if (grouped[dateStr] == null) {
          grouped[dateStr] = [];
        }
        grouped[dateStr]!.add(activity);
      }
      setState(() {
        _allGroupedActivities = grouped;
        _filteredGroupedActivities = Map.from(grouped);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDate(String dateStr) async {
    final date = DateTime.parse(dateStr);
    final displayDate = DateFormat('dd-MM-yyyy').format(date);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'archive'),
        content: Text(
          'Voulez-vous vraiment supprimer toutes les activités du $displayDate ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _staffService.deleteActivityDate(date);
        _loadActivities();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archive supprimée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = _filteredGroupedActivities.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return MainLayout(
      title: 'Activités',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: SearchFilterBar(
              controller: _searchController,
              hintText: 'Rechercher par date (JJ-MM-AAAA)...',
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadActivities,
                    child: sortedDates.isEmpty
                        ? const Center(child: Text('Aucune activité trouvée'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(24.0),
                            itemCount: sortedDates.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final dateStr = sortedDates[index];
                              final date = DateTime.parse(dateStr);
                              final activities = _filteredGroupedActivities[dateStr]!;
                              final displayDate = DateFormat(
                                'dd-MM-yyyy',
                              ).format(date);

                              return Container(
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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  title: Text(
                                    displayDate,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${activities.length} activité${activities.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () => _deleteDate(dateStr),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DailyActivitiesScreen(
                                          date: date,
                                          activities: activities,
                                        ),
                                      ),
                                    ).then((_) => _loadActivities());
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
