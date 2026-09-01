import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/conversation.dart';

final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  return ref.read(chatRepositoryProvider).conversations();
});

final messagesProvider =
    FutureProvider.autoDispose.family<List<Message>, String>((ref, id) async {
  return ref.read(chatRepositoryProvider).messages(id);
});
