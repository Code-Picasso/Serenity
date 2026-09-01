import '../datasources/remote/notification_remote.dart';
import '../models/notification.dart';

class NotificationRepository {
  final NotificationRemote _remote;

  NotificationRepository(this._remote);

  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 50}) =>
      _remote.getNotifications(page: page, limit: limit);

  Future<int> unreadCount() => _remote.unreadCount();

  Future<void> markRead(String id) => _remote.markRead(id);

  Future<void> markAllRead() => _remote.markAllRead();

  Future<void> delete(String id) => _remote.delete(id);
}
