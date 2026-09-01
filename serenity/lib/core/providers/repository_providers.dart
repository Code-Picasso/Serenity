import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/auth_remote.dart';
import '../../data/datasources/remote/chat_remote.dart';
import '../../data/datasources/remote/feed_remote.dart';
import '../../data/datasources/remote/notification_remote.dart';
import '../../data/datasources/remote/post_remote.dart';
import '../../data/datasources/remote/user_remote.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/feed_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(AuthRemote()),
);

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepository(FeedRemote()),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(PostRemote()),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(UserRemote()),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ChatRemote()),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(NotificationRemote()),
);
