import 'dart:io';

import '../datasources/remote/post_remote.dart';
import '../models/paginated.dart';
import '../models/post.dart';

class PostRepository {
  final PostRemote _remote;

  PostRepository(this._remote);

  Future<Paginated<Post>> getPosts({int page = 1, int limit = 20}) =>
      _remote.getPosts(page: page, limit: limit);

  Future<List<Post>> getUserPosts(String userId) => _remote.getUserPosts(userId);

  Future<Post> createPost({String text = '', String? imageUrl}) =>
      _remote.createPost(text: text, imageUrl: imageUrl);

  Future<String> uploadImage(File file) => _remote.uploadImage(file);

  Future<void> deletePost(String id) => _remote.deletePost(id);

  Future<bool> toggleLike(String id) => _remote.toggleLike(id);

  Future<Post> reshare(String id) => _remote.reshare(id);

  Future<void> savePost(String id) => _remote.savePost(id);

  Future<void> unsavePost(String id) => _remote.unsavePost(id);

  Future<List<Post>> savedPosts() => _remote.savedPosts();

  Future<List<Post>> resharedPosts() => _remote.resharedPosts();
}
