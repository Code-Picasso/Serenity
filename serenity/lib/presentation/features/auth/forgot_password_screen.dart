import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/repository_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _newPassword = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_sent) ...[
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy ? null : _requestReset,
                  child: const Text('Send reset link'),
                ),
              ] else ...[
                Text(
                  'A reset token was generated. In production it is emailed; in local mode it is shown below.',
                  style: context.textTheme.bodyMedium?.copyWith(color: context.themeExt.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _token,
                  decoration: const InputDecoration(labelText: 'Reset token', prefixIcon: Icon(Icons.key)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy ? null : _reset,
                  child: const Text('Update password'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestReset() async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      if (mounted) {
        final devToken = res['devResetToken'];
        if (devToken is String && devToken.isNotEmpty) {
          _token.text = devToken;
        }
        setState(() => _sent = true);
        context.showSnack(res['message'] as String? ?? 'Check your email.');
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: _token.text.trim(),
            newPassword: _newPassword.text,
          );
      if (mounted) {
        context.showSnack('Password updated. You can now sign in.');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
