class AuthUser {
  final int id;
  final String email;
  final String name;

  AuthUser({required this.id, required this.email, required this.name});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class AuthSession {
  final String accessToken;
  final AuthUser user;

  AuthSession({required this.accessToken, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] ?? '',
      user: AuthUser.fromJson(json['user'] ?? {}),
    );
  }
}
