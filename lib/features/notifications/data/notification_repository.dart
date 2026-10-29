import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient? _supabase;

  final List<NotificationModel> _localNotifications = [
    NotificationModel(
      id: 'n-001',
      recipientId: 'mock-user-customer',
      title: 'Booking Confirmed',
      message: 'Your booking for Van-Vans (Toyota HiAce) on Oct 30, 2026 at 08:30 AM has been confirmed.',
      type: 'confirmed',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationModel(
      id: 'n-002',
      recipientId: 'mock-user-customer',
      title: 'Departure Reminder',
      message:
          'Your scheduled trip from Catbalogan to Tacloban departs in 2 hours.',
      type: 'reminder',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'n-003',
      recipientId: 'mock-user-customer',
      title: 'Payment Status: Cash at Terminal',
      message: 'Please present your Booking Reference RG-2026-8472 at the terminal counter before boarding.',
      type: 'info',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'n-004',
      recipientId: 'mock-user-customer',
      title: 'Trip Completed',
      message: 'Thank you for riding with City Tours Express. Rate your travel experience!',
      type: 'completed',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  NotificationRepository({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null);

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  Future<List<NotificationModel>> getNotifications(String recipientId) async {
    if (!isConnected) {
      return _localNotifications;
    }

    try {
      final res = await _supabase!
          .from('notifications')
          .select()
          .eq('recipient_id', recipientId)
          .order('created_at', ascending: false);
      return (res as List).map((j) => NotificationModel.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('Supabase notifications fallback: $e');
      return _localNotifications;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final idx = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _localNotifications[idx] = _localNotifications[idx].copyWith(
        isRead: true,
      );
    }

    if (isConnected) {
      try {
        await _supabase!
            .from('notifications')
            .update({'is_read': true})
            .eq('id', notificationId);
      } catch (e) {
        if (kDebugMode) print('Mark as read error: $e');
      }
    }
  }

  Future<void> markAllAsRead(String recipientId) async {
    for (int i = 0; i < _localNotifications.length; i++) {
      _localNotifications[i] = _localNotifications[i].copyWith(isRead: true);
    }

    if (isConnected) {
      try {
        await _supabase!
            .from('notifications')
            .update({'is_read': true})
            .eq('recipient_id', recipientId);
      } catch (e) {
        if (kDebugMode) print('Mark all read error: $e');
      }
    }
  }

  void addNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
  }) {
    _localNotifications.insert(
      0,
      NotificationModel(
        id: 'n-${DateTime.now().millisecondsSinceEpoch}',
        recipientId: recipientId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }
}
