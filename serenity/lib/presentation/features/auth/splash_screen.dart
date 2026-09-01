import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isLoading && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigate(auth.isLoggedIn));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(AppConfig.logoAsset, width: 120, height: 120, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              Text(
                AppConfig.appName,
                style: context.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConfig.appTagline,
                style: context.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigate(bool isLoggedIn) async {
    if (!mounted) return;
    if (!isLoggedIn) {
      context.pushAndRemoveUntil(AppRoutes.landing);
      return;
    }
    try {
      final interests = await ref.read(feedRepositoryProvider).getInterests();
      if (!mounted) return;
      context.pushAndRemoveUntil(interests.isEmpty ? AppRoutes.onboarding : AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      context.pushAndRemoveUntil(AppRoutes.home);
    }
  }
}
