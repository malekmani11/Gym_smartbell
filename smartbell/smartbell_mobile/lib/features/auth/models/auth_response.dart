class AuthResponse {
  final int    id;
  final String email;
  final String firstName;
  final String lastName;
  final String token;
  final String role;

  const AuthResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.token,
    required this.role,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────
  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  bool get isAdmin  => role == 'ROLE_ADMIN'  || role == 'ROLE_MANAGER';
  bool get isCoach  => role == 'ROLE_COACH';
  bool get isMember => role == 'ROLE_MEMBER';

  // ── Serialization ─────────────────────────────────────────────────────────
  factory AuthResponse.fromJson(Map<String, dynamic> j) {
    // Backend sends "role": "ROLE_ADMIN" (string).
    // Fallback handles old cached JSON that stored "roles": [...] (array).
    String role = '';
    if (j['role'] != null) {
      role = j['role'] as String;
    } else if (j['roles'] is List && (j['roles'] as List).isNotEmpty) {
      role = (j['roles'] as List).first as String;
    }

    return AuthResponse(
      id:        (j['id'] ?? 0).toInt(),
      email:     j['email']     ?? '',
      firstName: j['firstName'] ?? '',
      lastName:  j['lastName']  ?? '',
      token:     j['token']     ?? '',
      role:      role,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'email':     email,
    'firstName': firstName,
    'lastName':  lastName,
    'token':     token,
    'role':      role,
  };
}
