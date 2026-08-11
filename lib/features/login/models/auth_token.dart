/// Response dari `POST /auth/login`.
class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.tokenType,
  });

  final String accessToken;
  final String tokenType;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
    );
  }

  bool get isValid => accessToken.isNotEmpty;

  /// Sengaja tidak menyertakan nilai token agar tidak ikut terbawa ke log.
  @override
  String toString() => 'AuthToken(tokenType: $tokenType)';
}
