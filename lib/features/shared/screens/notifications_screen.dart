import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/main_layout.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Nouvelles photos',
        'message':
            'De nouvelles photos de Adam ont été publiées dans "Jeux extérieurs".',
        'time': 'Il y a 5 min',
        'isRead': false,
        'icon': Icons.image_rounded,
        'color': AppColors.primary,
      },
      {
        'title': 'Rappel',
        'message': 'N\'oubliez pas la réunion des parents demain à 17h.',
        'time': 'Il y a 2 heures',
        'isRead': false,
        'icon': Icons.calendar_today_rounded,
        'color': AppColors.secondary,
      },
      {
        'title': 'Message de la direction',
        'message': 'La garderie sera fermée ce vendredi pour travaux.',
        'time': 'Hier',
        'isRead': true,
        'icon': Icons.info_outline_rounded,
        'color': AppColors.accent,
      },
    ];

    return MainLayout(
      title: 'Notifications',
      showBackButton: true,
      showNotificationIcon: false,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: notification['isRead']
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: notification['isRead']
                  ? BorderSide.none
                  : BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification['color'].withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification['icon'],
                  color: notification['color'],
                  size: 24,
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    notification['title'],
                    style: TextStyle(
                      fontWeight: notification['isRead']
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!notification['isRead'])
                    Container(
                      height: 8,
                      width: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification['time'],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: () {
                // Marquer comme lu ou naviguer
              },
            ),
          );
        },
      ),
    );
  }
}
