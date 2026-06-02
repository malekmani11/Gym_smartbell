/// Session-only storage — data lives in memory only.
/// Cleared automatically when the app process is killed (app closed).
/// No persistence to disk: user must log in every new session.
class SecureStorage {
  SecureStorage._();

  static String? _token;
  static String? _userData;

  static Future<void> saveToken(String token) async {
    _token = token;
  }

  static Future<String?> getToken() async => _token;

  static Future<void> saveUser(String userJson) async {
    _userData = userJson;
  }

  static Future<String?> getUser() async => _userData;

  static Future<void> clear() async {
    _token    = null;
    _userData = null;
  }
}
