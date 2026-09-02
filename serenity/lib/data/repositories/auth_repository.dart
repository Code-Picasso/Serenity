import '../../core/errors/app_exception.dart';
import '../../core/storage/session_store.dart';
import '../datasources/remote/auth_remote.dart';
import '../models/user.dart';

class AuthRepository {
  final AuthRemote _remote;
  final SessionStore _store = SessionStore.instance;

  AuthRepository(this._remote);

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _remote.register(email: email, password: password, name: name);
  }

  Future<AuthResult> verifyEmail({required String code}) async {
    final result = await _remote.verifyEmail(code: code);
    await _persist(result);
    return result;
  }

  Future<Map<String, dynamic>> resendVerification(String email) =>
      _remote.resendVerification(email);

  Future<AuthResult> login({required String email, required String password}) async {
    final result = await _remote.login(email: email, password: password);
    await _persist(result);
    return result;
  }

  Future<AuthResult> refresh() async {
    final token = await _store.refreshToken();
    if (token == null) throw const UnauthorizedException('No refresh token available.');
    final result = await _remote.refresh(token);
    await _persist(result);
    return result;
  }

  Future<void> logout() async {
    final token = await _store.refreshToken();
    try {
      await _remote.logout(token);
    } finally {
      await _store.clear();
    }
  }

  Future<User?> currentUser() async {
    final raw = await _store.user();
    if (raw == null) return null;
    return User.fromJson(raw);
  }

  Future<bool> isLoggedIn() => _store.isLoggedIn();

  Future<Map<String, dynamic>> forgotPassword(String email) => _remote.forgotPassword(email);

  Future<void> resetPassword({required String token, required String newPassword}) =>
      _remote.resetPassword(token: token, newPassword: newPassword);

  Future<void> _persist(AuthResult result) async {
    await _store.saveTokens(
      access: result.tokens.accessToken,
      refresh: result.tokens.refreshToken,
    );
    await _store.saveUser(result.user.toJson());
  }
}
