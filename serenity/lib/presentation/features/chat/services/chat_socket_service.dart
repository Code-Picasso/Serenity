import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/session_store.dart';
import '../../../../data/models/conversation.dart';

/// Wraps a Socket.IO connection to the chat service (through the gateway).
/// Text messages are sent/received in real time; history is fetched via REST.
class ChatSocketService {
  ChatSocketService._();

  static final ChatSocketService instance = ChatSocketService._();

  io.Socket? _socket;
  final _messageController = StreamController<Message>.broadcast();

  Stream<Message> get messages => _messageController.stream;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null) return;
    final token = await SessionStore.instance.accessToken();
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token ?? ''})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('conversation:message', (data) {
      if (data is Map) {
        _messageController.add(Message.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    _socket!.connect();
  }

  void joinConversation(String id) => _socket?.emit('conversation:join', id);

  void sendText(String conversationId, String content) {
    _socket?.emit('conversation:send', {
      'conversationId': conversationId,
      'content': content,
      'type': 'text',
    });
  }

  void sendTyping(String conversationId, bool isTyping) {
    _socket?.emit('conversation:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
