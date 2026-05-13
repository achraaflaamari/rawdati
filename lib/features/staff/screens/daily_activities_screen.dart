import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../../core/services/staff_service.dart';
import '../../shared/widgets/main_layout.dart';
import '../../shared/widgets/search_filter_bar.dart';
import 'activity_detail_screen.dart';
import 'edit_activity_screen.dart';

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
  final _staffService = StaffService();
  late List<Activity> _currentActivities;
  late List<Activity> _filteredActivities;
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _currentActivities = List.from(widget.activities);
    _filteredActivities = _currentActivities;
    _searchController.addListener(_filterActivities);
  }

  void _filterActivities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredActivities = _currentActivities.where((activity) {
        final matchesQuery = activity.title.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == null || 
                                activity.category == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'activité'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'activité "${activity.title}" ? Toutes les photos et assignations associées seront supprimées.',
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
        await _staffService.deleteActivity(activity.id);
        setState(() {
          _currentActivities.removeWhere((a) => a.id == activity.id);
          _filterActivities();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activité supprimée')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  void _editActivity(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(
          activity: activity,
          onUpdate: (updatedActivity) {
            setState(() {
              final index = _currentActivities.indexWhere((a) => a.id == updatedActivity.id);
              if (index != -1) {
                _currentActivities[index] = updatedActivity;
                _filterActivities();
              }
            });
          },
        ),
      ),
    );
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
            child: _filteredActivities.isEmpty
                ? const Center(child: Text('Aucune activité trouvée'))
                : ListView.separated(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: _filteredActivities.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final activity = _filteredActivities[index];
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
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
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
                          title: Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            activity.category ?? 'Général',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                onPressed: () => _editActivity(activity),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () => _deleteActivity(activity),
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
                                builder: (context) =>
                                    ActivityDetailScreen(activity: activity),
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

  void _showFilterBottomSheet(BuildContext context) {
    final categories = ['Général', 'Sport', 'Art', 'Musique', 'Lecture'];
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
              trailing: _selectedCategory == null
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                  _filterActivities();
                });
                Navigator.pop(context);
              },
            ),
            ...categories.map((cat) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(cat),
              trailing: _selectedCategory == cat
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _filterActivities();
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}
