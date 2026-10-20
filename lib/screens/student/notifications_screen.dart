import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notifications = provider.notifications
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: UniRideAppBar(title: 'Notifications'),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle: 'Reservation updates and alerts will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, i) {
                final n = notifications[i];
                return _NotificationCard(notification: n);
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.reservation:
        return Icons.confirmation_num_rounded;
      case NotificationType.cancellation:
        return Icons.cancel_rounded;
      case NotificationType.penalty:
        return Icons.warning_amber_rounded;
      case NotificationType.busUpdate:
        return Icons.directions_bus_rounded;
      case NotificationType.extraBus:
        return Icons.add_circle_rounded;
      case NotificationType.admin:
        return Icons.admin_panel_settings_rounded;
      case NotificationType.chat:
        return Icons.smart_toy_rounded;
    }
  }

  Color get _color {
    switch (notification.type) {
      case NotificationType.reservation:
        return AppColors.success;
      case NotificationType.cancellation:
        return AppColors.warning;
      case NotificationType.penalty:
        return AppColors.error;
      case NotificationType.busUpdate:
        return AppColors.blue;
      case NotificationType.extraBus:
        return AppColors.orange;
      case NotificationType.admin:
        return AppColors.purple;
      case NotificationType.chat:
        return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return GestureDetector(
      onTap: () => provider.markNotificationRead(notification.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          borderColor: !notification.isRead
              ? _color.withOpacity(0.4)
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM d, HH:mm')
                          .format(notification.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
