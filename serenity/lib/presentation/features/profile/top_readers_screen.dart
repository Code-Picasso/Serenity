import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/user_avatar.dart';
import 'providers/profile_providers.dart';

class TopReadersScreen extends ConsumerWidget {
  const TopReadersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readers = ref.watch(topReadersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Top readers')),
      body: readers.when(
        data: (profiles) => profiles.isEmpty
            ? const Center(child: Text('No readers yet.'))
            : ListView.builder(
                itemCount: profiles.length,
                itemBuilder: (_, i) {
                  final p = profiles[i];
                  return ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#${i + 1}',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: i < 3 ? context.themeExt.primary : context.themeExt.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        UserAvatar(name: p.displayName, imageUrl: p.avatarUrl),
                      ],
                    ),
                    title: Text(p.displayName),
                    subtitle: Text('${p.activityScore} activity points'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.profile, arguments: p),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(topReadersProvider),
        ),
      ),
    );
  }
}
