class Article {
  final String id;
  final String source;
  final String sourceId;
  final String title;
  final String description;
  final String content;
  final String url;
  final String? imageUrl;
  final String? author;
  final String category;
  final String topic;
  final DateTime? publishedAt;

  const Article({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    this.imageUrl,
    this.author,
    required this.category,
    this.topic = '',
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String? ?? '',
        source: json['source'] as String? ?? '',
        sourceId: json['sourceId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        content: json['content'] as String? ?? '',
        url: json['url'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        author: json['author'] as String?,
        category: json['category'] as String? ?? 'news',
        topic: json['topic'] as String? ?? '',
        publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      );

  /// Preferred display label — the specific interest if present, else category.
  String get label => topic.isNotEmpty ? topic : category;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}
