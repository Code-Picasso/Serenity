import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/time_ago.dart';
import '../../../data/models/conversation.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/user_avatar.dart';
import 'providers/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewChat(context, ref),
        child: const Icon(Icons.add_comment_rounded),
      ),
      body: conversations.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No conversations yet. Start one!'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final c = items[i];
                  return ListTile(
                    leading: const UserAvatar(name: 'Chat'),
                    title: Text(c.isGroup ? (c.name ?? 'Group') : 'Direct message'),
                    subtitle: Text(
                      c.lastMessage?.content ?? c.lastMessage?.mediaUrl ?? 'Start chatting',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(timeAgo(c.updatedAt)),
                    onTap: () => context.push(AppRoutes.chatDetail, arguments: c),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
      ),
    );
  }

  Future<void> _startNewChat(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final userId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'User ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (userId == null || userId.isEmpty) return;
    try {
      final id = await ref.read(chatRepositoryProvider).createConversation(userId);
      ref.invalidate(conversationsProvider);
      if (context.mounted) {
        context.push(AppRoutes.chatDetail, arguments: Conversation(id: id));
      }
    } catch (e) {
      if (context.mounted) context.showSnack(e.toString());
    }
  }
}
