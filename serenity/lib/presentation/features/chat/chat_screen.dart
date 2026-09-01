import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/url_utils.dart';
import '../../../data/models/conversation.dart';
import '../auth/providers/auth_providers.dart';
import 'services/chat_socket_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <Message>[];
  final _ids = <String>{};
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  StreamSubscription<Message>? _sub;

  String? _myId;
  bool _recording = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _myId = ref.read(authControllerProvider).user?.id;
    _loadHistory();
    _connectSocket();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _recorder.dispose();
    _player.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final msgs = await ref.read(chatRepositoryProvider).messages(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        for (final m in msgs) {
          _addMessage(m);
        }
      });
      await ref.read(chatRepositoryProvider).markRead(widget.conversation.id);
    } catch (_) {}
  }

  void _addMessage(Message m) {
    if (_ids.contains(m.id)) return;
    _ids.add(m.id);
    _messages.add(m);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _connectSocket() {
    final service = ChatSocketService.instance;
    service.connect().then((_) => service.joinConversation(widget.conversation.id));
    _sub = service.messages.listen((m) {
      if (m.conversationId == widget.conversation.id) {
        _addMessage(m);
      }
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final service = ChatSocketService.instance;
    if (service.isConnected) {
      service.sendText(widget.conversation.id, text);
    } else {
      try {
        final msg = await ref.read(chatRepositoryProvider).sendText(widget.conversation.id, text);
        _addMessage(msg);
      } catch (e) {
        if (mounted) context.showSnack(e.toString());
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() => _recording = false);
      if (path != null) await _sendAudio(File(path));
    } else {
      if (!await _recorder.hasPermission()) {
        if (mounted) context.showSnack('Microphone permission is required.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      if (mounted) setState(() => _recording = true);
    }
  }

  Future<void> _sendAudio(File file) async {
    setState(() => _sending = true);
    try {
      final msg = await ref.read(chatRepositoryProvider).sendAudio(widget.conversation.id, file);
      _addMessage(msg);
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _play(Message m) async {
    if (m.mediaUrl == null) return;
    await _player.stop();
    await _player.play(UrlSource(resolveUrl(m.mediaUrl)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.conversation.isGroup ? (widget.conversation.name ?? 'Group') : 'Chat';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return _Bubble(
                  message: m,
                  isMine: m.senderId == _myId,
                  onPlayAudio: () => _play(m),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _toggleRecording,
                    icon: Icon(
                      _recording ? Icons.stop_circle : Icons.mic_none,
                      color: _recording ? Theme.of(context).colorScheme.error : null,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      decoration: InputDecoration(
                        hintText: _recording ? 'Recording audio…' : 'Type a message',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendText,
                    icon: const Icon(Icons.send_rounded),
                    color: context.themeExt.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final VoidCallback onPlayAudio;

  const _Bubble({required this.message, required this.isMine, required this.onPlayAudio});

  @override
  Widget build(BuildContext context) {
    final ext = context.themeExt;
    final bubbleColor = isMine ? ext.primary : ext.surfaceElevated;
    final textColor = isMine ? Colors.white : ext.textPrimary;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: message.isAudio
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onPlayAudio,
                    child: Icon(Icons.play_circle_fill, color: textColor, size: 30),
                  ),
                  const SizedBox(width: 8),
                  Text('Voice message', style: TextStyle(color: textColor)),
                ],
              )
            : Text(message.content ?? '', style: TextStyle(color: textColor)),
      ),
    );
  }
}
