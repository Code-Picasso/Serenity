/// The gender options offered at sign-up. The wire value is the snake_case
/// [value]; [label] is what the UI shows.
enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other'),
  preferNotToSay('prefer_not_to_say', 'Prefer not to say');

  const Gender(this.value, this.label);

  final String value;
  final String label;

  static Gender? fromValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final g in Gender.values) {
      if (g.value == value) return g;
    }
    return null;
  }
}

class User {
  final String id;
  final String username;
  final String name;
  final String gender;
  final String? avatarUrl;
  final String? provider;

  const User({
    required this.id,
    required this.username,
    required this.name,
    this.gender = '',
    this.avatarUrl,
    this.provider,
  });

  /// Human-readable gender label, or an empty string when unset/unknown.
  String get genderLabel => Gender.fromValue(gender)?.label ?? '';

  String get handle => username.isNotEmpty ? '@$username' : '';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        name: json['name'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        provider: json['provider'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'gender': gender,
        'avatarUrl': avatarUrl,
        'provider': provider,
      };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
      );
}

class AuthResult {
  final User user;
  final AuthTokens tokens;

  const AuthResult({required this.user, required this.tokens});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json),
      );
}
