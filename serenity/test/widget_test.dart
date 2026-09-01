import 'package:flutter_test/flutter_test.dart';
import 'package:serenity/data/models/article.dart';
import 'package:serenity/data/models/profile.dart';

void main() {
  test('Article.fromJson parses fields and defaults', () {
    final article = Article.fromJson({
      'id': 'abc',
      'source': 'gnews',
      'sourceId': 'gnews-1',
      'title': 'Hello world',
      'description': 'A description',
      'content': 'Full content',
      'url': 'https://example.com',
      'category': 'news',
      'publishedAt': '2026-01-01T00:00:00Z',
    });

    expect(article.id, 'abc');
    expect(article.title, 'Hello world');
    expect(article.category, 'news');
    expect(article.publishedAt, isNotNull);
  });

  test('Profile derives displayName and handle', () {
    const profile = Profile(id: 'p1', userId: 'u1', name: 'Ada Lovelace', username: 'ada');

    expect(profile.displayName, 'Ada Lovelace');
    expect(profile.handle, '@ada');
  });
}
