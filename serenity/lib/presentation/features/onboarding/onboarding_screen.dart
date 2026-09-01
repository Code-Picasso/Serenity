import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_routes.dart';
import '../feed/providers/feed_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<String> _selected = {};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pick your interests')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Choose the topics you care about to personalise your feed.',
                style: context.textTheme.bodyLarge?.copyWith(color: context.themeExt.textSecondary),
              ),
            ),
            Expanded(
              child: topics.when(
                data: (catalog) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final section in catalog.sections) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          section.name,
                          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: section.topics
                            .map(
                              (t) => FilterChip(
                                label: Text(t),
                                selected: _selected.contains(t),
                                onSelected: (sel) => setState(() {
                                  sel ? _selected.add(t) : _selected.remove(t);
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load topics: $e')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _busy ? null : _continue,
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Continue'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => context.pushAndRemoveUntil(AppRoutes.home),
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await ref.read(feedRepositoryProvider).saveInterests(_selected.toList());
      if (mounted) context.pushAndRemoveUntil(AppRoutes.home);
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
