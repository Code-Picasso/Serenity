import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/article_card.dart';
import '../../widgets/post_card.dart';
import '../../widgets/user_avatar.dart';
import '../auth/providers/auth_providers.dart';
import '../feed/providers/feed_providers.dart';
import '../post/providers/post_providers.dart';
import 'providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.push(AppRoutes.saved),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _ProfileBody(profile: profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final dynamic profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    UserAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, radius: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.displayName,
                              style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          Text(profile.handle,
                              style: context.textTheme.bodySmall?.copyWith(color: context.themeExt.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(context, ref),
                    ),
                  ],
                ),
                if (profile.bio != null && profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: Text(profile.bio)),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(label: 'Score', value: '${profile.activityScore}'),
                    _Stat(label: 'Followers', value: '${profile.followersCount}'),
                    _Stat(label: 'Following', value: '${profile.followingCount}'),
                    _Stat(label: 'Posts', value: '${profile.postsCount}'),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _logout(context, ref),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [Tab(text: 'Posts'), Tab(text: 'Reshared'), Tab(text: 'Saved')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PostsTab(userId: profile.userId),
                const _ResharedTab(),
                const _SavedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController(text: profile.name);
    final username = TextEditingController(text: profile.username ?? '');
    final bio = TextEditingController(text: profile.bio ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            TextField(controller: bio, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      try {
        await ref.read(userRepositoryProvider).updateMe(
              name: name.text.trim(),
              username: username.text.trim(),
              bio: bio.text.trim(),
            );
        ref.invalidate(myProfileProvider);
      } catch (e) {
        if (context.mounted) context.showSnack(e.toString());
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.pushAndRemoveUntil(AppRoutes.landing);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: context.textTheme.bodySmall?.copyWith(color: context.themeExt.textSecondary)),
      ],
    );
  }
}

class _PostsTab extends ConsumerWidget {
  final String userId;
  const _PostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userPostsProvider(userId));
    return posts.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('No posts yet.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => PostCard(post: items[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load posts: $e')),
    );
  }
}

class _ResharedTab extends ConsumerWidget {
  const _ResharedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(resharedPostsProvider);
    return posts.when(
      data: (items) => items.isEmpty
          ? const Center(child: Text('Nothing reshared yet.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => PostCard(post: items[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load reshared: $e')),
    );
  }
}

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(savedPostsProvider);
    final articles = ref.watch(savedArticlesProvider);
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Saved articles', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ...articles.maybeWhen(
          data: (items) => items.isEmpty
              ? [const Padding(padding: EdgeInsets.all(16), child: Text('No saved articles.'))]
              : items.map((a) => ArticleCard(article: a)).toList(),
          orElse: () => const [SizedBox.shrink()],
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Saved posts', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ...posts.maybeWhen(
          data: (items) => items.isEmpty
              ? [const Padding(padding: EdgeInsets.all(16), child: Text('No saved posts.'))]
              : items.map((p) => PostCard(post: p)).toList(),
          orElse: () => const [SizedBox.shrink()],
        ),
      ],
    );
  }
}
