import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;

  const AuthState({this.user, this.isLoading = false});

  bool get isLoggedIn => user != null;

  AuthState copyWith({User? user, bool? isLoading}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _bootstrap();
    return const AuthState(isLoading: true);
  }

  Future<void> _bootstrap() async {
    final user = await ref.read(authRepositoryProvider).currentUser();
    state = AuthState(user: user, isLoading: false);
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = AuthState(user: result.user, isLoading: false);
    } catch (_) {
      state = const AuthState(isLoading: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .register(email: email, password: password, name: name);
      state = const AuthState(isLoading: false);
      return result;
    } catch (_) {
      state = const AuthState(isLoading: false);
      rethrow;
    }
  }

  Future<void> verifyEmail({required String code}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result =
          await ref.read(authRepositoryProvider).verifyEmail(code: code);
      state = AuthState(user: result.user, isLoading: false);
    } catch (_) {
      state = const AuthState(isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(isLoading: false);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
