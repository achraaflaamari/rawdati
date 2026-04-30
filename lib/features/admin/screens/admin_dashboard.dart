import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/main_layout.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Enfants',
        'value': '48',
        'icon': 'assets/illustrations/icon_13.svg',
        'color': AppColors.primary,
      },
      {
        'title': 'Staff',
        'value': '12',
        'icon': 'assets/illustrations/icon_14.svg',
        'color': AppColors.secondary,
      },
      {
        'title': 'Parents',
        'value': '85',
        'icon': 'assets/illustrations/icon_15.svg',
        'color': AppColors.accent,
      },
      {
        'title': 'Groupes',
        'value': '6',
        'icon': 'assets/illustrations/icon_16.svg',
        'color': AppColors.primary,
      },
      {
        'title': 'Photos',
        'value': '1.2k',
        'icon': 'assets/illustrations/icon_17.svg',
        'color': AppColors.secondary,
      },
      {
        'title': 'Activités',
        'value': '24',
        'icon': 'assets/illustrations/icon_18.svg',
        'color': AppColors.accent,
      },
    ];

    return MainLayout(
      title: 'Statistiques',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aperçu de la Garderie',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Statistiques générales de l\'établissement',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: stat['color'].withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: stat['color'].withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              stat['icon'],
                              placeholderBuilder: (context) =>
                                  const CircularProgressIndicator(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stat['value'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  stat['title'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
