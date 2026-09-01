import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../auth/providers/auth_providers.dart';
import '../profile/providers/profile_providers.dart';
import 'providers/post_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _text = TextEditingController();
  File? _image;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create post'),
        actions: [
          TextButton(onPressed: _busy ? null : _submit, child: const Text('Post')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _text,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Add image'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_text.text.trim().isEmpty && _image == null) {
      context.showSnack('Add some text or an image.');
      return;
    }
    setState(() => _busy = true);
    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await ref.read(postRepositoryProvider).uploadImage(_image!);
      }
      await ref.read(postRepositoryProvider).createPost(text: _text.text.trim(), imageUrl: imageUrl);

      final userId = ref.read(authControllerProvider).user?.id;
      ref.invalidate(postsProvider);
      ref.invalidate(userPostsProvider(userId ?? ''));
      ref.invalidate(myProfileProvider);

      if (mounted) {
        context.showSnack('Post published');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
