import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/profile.dart';
import '../../widgets/post_card.dart';
import '../../widgets/user_avatar.dart';
import '../post/providers/post_providers.dart';
import 'providers/profile_providers.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final Profile profile;
  const UserProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    try {
      final result = await ref.read(userRepositoryProvider).getProfile(widget.profile.userId);
      if (mounted) setState(() => _following = result.isFollowing);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      appBar: AppBar(title: Text(p.displayName)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                UserAvatar(name: p.displayName, imageUrl: p.avatarUrl, radius: 40),
                const SizedBox(height: 12),
                Text(p.displayName, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(p.handle, style: context.textTheme.bodySmall?.copyWith(color: context.themeExt.textSecondary)),
                if ((p.bio ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.bio!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Count(label: 'Score', value: p.activityScore),
                    _Count(label: 'Followers', value: p.followersCount),
                    _Count(label: 'Posts', value: p.postsCount),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _following ? context.themeExt.surfaceHigh : context.themeExt.primary,
                    ),
                    child: Text(_following ? 'Following' : 'Follow'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Posts', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          _UserPosts(userId: p.userId),
        ],
      ),
    );
  }

  Future<void> _toggleFollow() async {
    try {
      if (_following) {
        await ref.read(userRepositoryProvider).unfollow(widget.profile.userId);
      } else {
        await ref.read(userRepositoryProvider).follow(widget.profile.userId);
      }
      setState(() => _following = !_following);
      ref.invalidate(profileProvider(widget.profile.userId));
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    }
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  const _Count({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: context.textTheme.bodySmall?.copyWith(color: context.themeExt.textSecondary)),
      ],
    );
  }
}

class _UserPosts extends ConsumerWidget {
  final String userId;
  const _UserPosts({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userPostsProvider(userId));
    return posts.when(
      data: (items) => items.isEmpty
          ? const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No posts yet.')))
          : Column(children: items.map((p) => PostCard(post: p)).toList()),
      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Failed: $e'))),
    );
  }
}
