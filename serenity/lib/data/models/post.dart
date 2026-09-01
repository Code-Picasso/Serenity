class Post {
  final String id;
  final String userId;
  final String text;
  final String? imageUrl;
  final String? reshareId;
  final int likeCount;
  final DateTime? createdAt;

  const Post({
    required this.id,
    required this.userId,
    required this.text,
    this.imageUrl,
    this.reshareId,
    this.likeCount = 0,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        text: json['text'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        reshareId: json['reshareId'] as String?,
        likeCount: json['likeCount'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  bool get isReshare => reshareId != null && reshareId!.isNotEmpty;
}
