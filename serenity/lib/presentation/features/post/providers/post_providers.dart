import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/post.dart';

final postsProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  final result = await ref.read(postRepositoryProvider).getPosts();
  return result.items;
});

final savedPostsProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  return ref.read(postRepositoryProvider).savedPosts();
});

final resharedPostsProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  return ref.read(postRepositoryProvider).resharedPosts();
});

final userPostsProvider = FutureProvider.autoDispose.family<List<Post>, String>(
  (ref, userId) async => ref.read(postRepositoryProvider).getUserPosts(userId),
);
