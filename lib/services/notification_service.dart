import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'push_notification_service.dart';
import 'sms_service.dart';
import 'offline_sync_service.dart';
import '../models/system_models.dart';
import 'user_provider.dart';

class NotificationNotifier extends StateNotifier<List<SystemNotification>> {
  final Ref ref;
  NotificationNotifier(this.ref) : super([]);

  void addNotification(String title, String message, {String type = 'info'}) async {
    final user = ref.read(currentUserProvider);
    final notification = SystemNotification(
      id: '00000000-0000-0000-0000-${DateTime.now().millisecondsSinceEpoch}',
      branchCode: user?.branchCode,
      userId: user?.id,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    );
    
    state = [notification, ...state];

    // 1. Persist to Offline Queue
    await OfflineSyncService.addToQueue(
      actionType: 'NOTIFICATION', 
      data: notification.toJson(),
    );

    // 2. Show System Tray "Popup" Notification
    PushNotificationService.showNotification(
      id: notification.createdAt.millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
    );

    // 3. If it's a critical alert, send SMS to Admin (Works even if app is closed/offline)
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
        if (n.id == id) SystemNotification(
          id: n.id, 
          branchCode: n.branchCode,
          userId: n.userId,
          title: n.title, 
          message: n.message, 
          type: n.type,
          createdAt: n.createdAt, 
          isRead: true
        )
        else n
    ];
    // TODO: Sync read status to Supabase
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<SystemNotification>>((ref) {
  return NotificationNotifier(ref);
});
