import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_header.dart';
import '../data/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifRepo = NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final list = await _notifRepo.getNotifications('mock-user-customer');
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await _notifRepo.markAllAsRead('mock-user-customer');
    await _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  Future<void> _toggleRead(NotificationModel n) async {
    if (!n.isRead) {
      await _notifRepo.markAsRead(n.id);
      await _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Notifications',
            subtitle: 'Stay updated with your bookings',
            actions: [
              TextButton(
                onPressed: _markAllAsRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppColors.accentCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.headerNavy,
                      ),
                    ),
                  )
                : _notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(
                        color: AppColors.headerNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return GestureDetector(
                        onTap: () => _toggleRead(n),
                        child: _buildNotificationCard(n),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    IconData icon;
    Color iconColor;

    switch (n.type) {
      case 'confirmed':
      case 'booking_confirmed':
        icon = Icons.check_circle;
        iconColor = AppColors.statusConfirmed;
        break;
      case 'reminder':
      case 'schedule_change':
        icon = Icons.alarm;
        iconColor = AppColors.statusPending;
        break;
      case 'completed':
      case 'booking_completed':
        icon = Icons.task_alt;
        iconColor = AppColors.statusCompleted;
        break;
      case 'operator_approved':
        icon = Icons.verified;
        iconColor = AppColors.statusConfirmed;
        break;
      default:
        icon = Icons.info;
        iconColor = AppColors.buttonTeal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white.withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: n.isRead
              ? AppColors.inputBorder.withOpacity(0.5)
              : AppColors.buttonTeal,
          width: n.isRead ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      DateFormatter.formatShortDate(n.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  n.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: n.isRead
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
