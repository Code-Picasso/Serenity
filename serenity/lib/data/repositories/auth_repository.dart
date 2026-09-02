import '../../core/errors/app_exception.dart';
import '../../core/storage/session_store.dart';
import '../datasources/remote/auth_remote.dart';
import '../models/user.dart';

class AuthRepository {
  final AuthRemote _remote;
  final SessionStore _store = SessionStore.instance;

  AuthRepository(this._remote);

  Future<AuthResult> register({
    required String username,
    required String password,
    required String name,
    required String gender,
  }) async {
    final result = await _remote.register(
      username: username,
      password: password,
      name: name,
      gender: gender,
    );
    await _persist(result);
    return result;
  }

  Future<AuthResult> login({required String username, required String password}) async {
    final result = await _remote.login(username: username, password: password);
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

  Future<void> _persist(AuthResult result) async {
    await _store.saveTokens(
      access: result.tokens.accessToken,
      refresh: result.tokens.refreshToken,
    );
    await _store.saveUser(result.user.toJson());
  }
}
