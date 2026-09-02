import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_routes.dart';
import 'providers/auth_providers.dart';

class VerifyEmailArgs {
  final String email;
  final String? devToken;

  const VerifyEmailArgs({required this.email, this.devToken});
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final VerifyEmailArgs args;

  const VerifyEmailScreen({super.key, required this.args});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final dev = widget.args.devToken;
    if (dev != null && dev.isNotEmpty) _code.text = dev;
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'We sent a 6-digit code to ${widget.args.email}. Enter it below to verify your account.',
                style: context.textTheme.bodyMedium?.copyWith(color: context.themeExt.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  prefixIcon: Icon(Icons.verified_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (auth.isLoading || _busy) ? null : _verify,
                child: (auth.isLoading || _busy)
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verify'),
              ),
              TextButton(
                onPressed: _busy ? null : _resend,
                child: const Text('Resend code'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      context.showSnack('Enter the 6-digit code from your email.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyEmail(code: code);
      if (mounted) context.pushAndRemoveUntil(AppRoutes.onboarding);
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(authRepositoryProvider).resendVerification(widget.args.email);
      if (mounted) {
        final dev = res['devVerificationToken'];
        if (dev is String && dev.isNotEmpty) _code.text = dev;
        context.showSnack(res['message'] as String? ?? 'Code resent.');
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
