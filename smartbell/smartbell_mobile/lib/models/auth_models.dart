class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class AuthResponse {
  final String token;
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;

  AuthResponse({
    required this.token,
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token:     json['token'] ?? '',
    id:        json['id'] ?? 0,
    email:     json['email'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName:  json['lastName'] ?? '',
    roles:     List<String>.from(json['roles'] ?? []),
  );

  String get fullName => '$firstName $lastName'.trim();

  bool get isAdmin   => roles.any((r) => r.contains('ADMIN'));
  bool get isManager => roles.any((r) => r.contains('MANAGER'));
  bool get isCoach   => roles.any((r) => r.contains('COACH'));
  bool get isMember  => roles.any((r) => r.contains('MEMBER'));
  bool get isStaff   => isAdmin || isManager;

  Map<String, dynamic> toJson() => {
    'token': token, 'id': id, 'email': email,
    'firstName': firstName, 'lastName': lastName, 'roles': roles,
  };
}
