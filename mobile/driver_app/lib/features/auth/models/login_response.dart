class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String role;

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
        userId: json['user_id'] as int,
        role: json['role'] as String,
      );
}
