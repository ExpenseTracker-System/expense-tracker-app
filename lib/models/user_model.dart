class UserModel {
  final String id;
  final String username;
  final String email;
  final String authProvider;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.authProvider,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      authProvider: json['authProvider']?.toString() ?? 'LOCAL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'authProvider': authProvider,
    };
  }
}