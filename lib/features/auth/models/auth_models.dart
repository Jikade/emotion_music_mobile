class AuthUser {
  final int id;
  final String email;
  final String name;
  final String role;
  final bool isVip;
  final String? avatarUrl;
  final String? authProvider;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.isVip = false,
    this.avatarUrl,
    this.authProvider,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _toInt(json['id']),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isVip: _toBool(json['is_vip'] ?? json['isVip']),
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      authProvider:
          json['auth_provider']?.toString() ?? json['authProvider']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'is_vip': isVip,
      'avatar_url': avatarUrl,
      'auth_provider': authProvider,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'yes';
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;
  final AuthUser user;

  const TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] ?? {})),
    );
  }
}
