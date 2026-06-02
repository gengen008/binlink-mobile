class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken:  json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user:         Map<String, dynamic>.from(json['user'] as Map),
    );
  }
}
