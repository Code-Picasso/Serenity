import '../datasources/remote/user_remote.dart';
import '../models/profile.dart';

class UserRepository {
  final UserRemote _remote;

  UserRepository(this._remote);

  Future<Profile> me() => _remote.me();

  Future<Profile> updateMe({
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
  }) =>
      _remote.updateMe(
        name: name,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
        isPublic: isPublic,
      );

  Future<ProfileResult> getProfile(String userId) => _remote.getProfile(userId);

  Future<List<Profile>> topReaders({int limit = 20}) => _remote.topReaders(limit: limit);

  Future<void> follow(String userId) => _remote.follow(userId);

  Future<void> unfollow(String userId) => _remote.unfollow(userId);

  Future<List<Profile>> followers(String userId) => _remote.followers(userId);

  Future<List<Profile>> following(String userId) => _remote.following(userId);
}
