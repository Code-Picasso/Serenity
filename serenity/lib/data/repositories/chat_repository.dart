import 'dart:io';

import '../datasources/remote/chat_remote.dart';
import '../models/conversation.dart';

class ChatRepository {
  final ChatRemote _remote;

  ChatRepository(this._remote);

  Future<List<Conversation>> conversations() => _remote.conversations();

  Future<String> createConversation(String userId) => _remote.createConversation(userId);

  Future<Conversation> getConversation(String id) => _remote.getConversation(id);

  Future<List<Message>> messages(String id, {int page = 1, int limit = 50}) =>
      _remote.messages(id, page: page, limit: limit);

  Future<Message> sendText(String id, String content) => _remote.sendText(id, content);

  Future<Message> sendAudio(String id, File audio) => _remote.sendAudio(id, audio);

  Future<void> markRead(String id) => _remote.markRead(id);
}
