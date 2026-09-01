import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../data/datasources/remote/user_remote.dart';
import '../../../../data/models/profile.dart';

final myProfileProvider = FutureProvider.autoDispose<Profile>((ref) async {
  return ref.read(userRepositoryProvider).me();
});

final profileProvider =
    FutureProvider.autoDispose.family<ProfileResult, String>((ref, userId) async {
  return ref.read(userRepositoryProvider).getProfile(userId);
});

final topReadersProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  return ref.read(userRepositoryProvider).topReaders();
});
