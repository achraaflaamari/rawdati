import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../../core/services/staff_service.dart';
import '../../shared/widgets/main_layout.dart';
import 'daily_activities_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final _staffService = StaffService();
  Map<String, List<Activity>> _groupedActivities = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _staffService.getAllActivities();
      final Map<String, List<Activity>> grouped = {};
      for (var activity in activities) {
        final dateStr = DateFormat('yyyy-MM-dd').format(activity.activityDate);
        if (grouped[dateStr] == null) {
          grouped[dateStr] = [];
        }
        grouped[dateStr]!.add(activity);
      }
      setState(() {
        _groupedActivities = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = _groupedActivities.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return MainLayout(
      title: 'Activités',
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
                        final activities = _groupedActivities[dateStr]!;
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
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
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
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
