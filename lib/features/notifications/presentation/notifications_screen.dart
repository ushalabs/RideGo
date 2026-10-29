import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'n-1',
      'title': 'Booking Confirmed',
      'message': 'Your booking for Van-Vans (Toyota HiAce) on Oct 30, 2026 at 08:30 AM has been confirmed.',
      'time': '10 mins ago',
      'isRead': false,
      'type': 'confirmed',
    },
    {
      'id': 'n-2',
      'title': 'Departure Reminder',
      'message': 'Your scheduled trip from Catbalogan to Tacloban departs tomorrow morning.',
      'time': '2 hours ago',
      'isRead': false,
      'type': 'reminder',
    },
    {
      'id': 'n-3',
      'title': 'Payment Status: Cash at Terminal',
      'message': 'Please present your Booking Reference RG-2026-8472 at the terminal counter before boarding.',
      'time': '1 day ago',
      'isRead': true,
      'type': 'info',
    },
    {
      'id': 'n-4',
      'title': 'Trip Completed',
      'message': 'Thank you for riding with City Tours Express. Rate your travel experience!',
      'time': '5 days ago',
      'isRead': true,
      'type': 'completed',
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Navy Header matching Figma
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

          // Notifications List
          Expanded(
            child: _notifications.isEmpty
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
                      return _buildNotificationCard(n);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    IconData icon;
    Color iconColor;

    switch (n['type']) {
      case 'confirmed':
        icon = Icons.check_circle;
        iconColor = AppColors.statusConfirmed;
        break;
      case 'reminder':
        icon = Icons.alarm;
        iconColor = AppColors.statusPending;
        break;
      case 'completed':
        icon = Icons.task_alt;
        iconColor = AppColors.statusCompleted;
        break;
      default:
        icon = Icons.info;
        iconColor = AppColors.buttonTeal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: n['isRead'] ? Colors.white.withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: n['isRead']
              ? AppColors.inputBorder.withOpacity(0.5)
              : AppColors.buttonTeal,
          width: n['isRead'] ? 1.0 : 1.5,
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
                        n['title'],
                        style: TextStyle(
                          fontWeight: n['isRead']
                              ? FontWeight.w600
                              : FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      n['time'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  n['message'],
                  style: TextStyle(
                    fontSize: 12,
                    color: n['isRead']
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
