import 'package:flutter/foundation.dart';
import '../models/notification.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Initialize with some mock notifications
  void initializeMockNotifications() {
    _notifications.clear();
    _notifications.addAll([
      AppNotification(
        id: '1',
        title: 'New Message from Sarah Johnson',
        message: 'Your consultation has been confirmed for tomorrow at 2 PM.',
        type: NotificationType.message,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: '2',
        title: 'Booking Reminder',
        message:
            'Don\'t forget about your appointment with John Smith tomorrow.',
        type: NotificationType.reminder,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      AppNotification(
        id: '3',
        title: 'Document Uploaded Successfully',
        message: 'Your legal document has been uploaded and is being reviewed.',
        type: NotificationType.update,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: '4',
        title: 'New Lawyer Available',
        message: 'A criminal law specialist is now available in your area.',
        type: NotificationType.promotion,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: '5',
        title: 'Consultation Completed',
        message: 'Please rate your experience with Dr. Michael Brown.',
        type: NotificationType.booking,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AppNotification(
        id: '6',
        title: 'Payment Confirmation',
        message: 'Your payment of \$150 has been processed successfully.',
        type: NotificationType.update,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);
    notifyListeners();
  }

  /// Add a new notification
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  /// Delete a notification
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }
}







