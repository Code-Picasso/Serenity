import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/notification.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return ref.read(notificationRepositoryProvider).getNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(notificationRepositoryProvider).unreadCount();
});
