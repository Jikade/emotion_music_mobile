class AuthUser {
  final int id;
  final String email;
  final String name;
  final String role;
  final bool isVip;
  final String? avatarUrl;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.isVip = false,
    this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _toInt(json['id']),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isVip: json['is_vip'] == true || json['isVip'] == true,
      avatarUrl: json['avatar_url']?.toString(),
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
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
