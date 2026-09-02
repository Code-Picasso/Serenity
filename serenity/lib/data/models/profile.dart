class Profile {
  final String id;
  final String userId;
  final String name;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final bool isPublic;
  final int activityScore;
  final int readsCount;
  final int sharesCount;
  final int postsCount;
  final int chatsCount;
  final int followersCount;
  final int followingCount;

  const Profile({
    required this.id,
    required this.userId,
    this.name = '',
    this.username,
    this.bio,
    this.avatarUrl,
    this.isPublic = true,
    this.activityScore = 0,
    this.readsCount = 0,
    this.sharesCount = 0,
    this.postsCount = 0,
    this.chatsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        username: json['username'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        isPublic: json['isPublic'] as bool? ?? true,
        activityScore: json['activityScore'] as int? ?? 0,
        readsCount: json['readsCount'] as int? ?? 0,
        sharesCount: json['sharesCount'] as int? ?? 0,
        postsCount: json['postsCount'] as int? ?? 0,
        chatsCount: json['chatsCount'] as int? ?? 0,
        followersCount: json['followersCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
      );

  String get displayName => name.isNotEmpty ? name : 'Serenity User';
  String get handle => username != null && username!.isNotEmpty ? '@$username' : '@user$userId'.substring(0, 8);
}
