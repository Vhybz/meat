import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'push_notification_service.dart';
import 'sms_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier() : super([]);

  void addNotification(String title, String message) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    state = [notification, ...state];

    // 1. Show System Tray "Popup" Notification
    PushNotificationService.showNotification(
      id: notification.timestamp.millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
    );

    // 2. If it's a critical alert, send SMS to Admin (Works even if app is closed/offline)
    final criticalKeywords = ['BUTCHER', 'RECTIFIED', 'URGENT', 'STOCK TRANSFER', 'LOW STOCK', 'CORRECTION'];
    bool isCritical = criticalKeywords.any((k) => title.toUpperCase().contains(k));

    if (isCritical) {
      SmsService.notifyAdmin(
        title: title,
        message: message,
      );
    }
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) AppNotification(id: n.id, title: n.title, message: n.message, timestamp: n.timestamp, isRead: true)
        else n
    ];
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier();
});
