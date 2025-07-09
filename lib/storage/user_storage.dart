import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _userIdKey = 'userId';
  static const String _emailKey = 'email';
  static const String _fullnameKey = 'fullname';
  static const String _tokenKey = 'firstname';

  static Future<void> saveUser(int userId, String email, String fullname, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_fullnameKey, fullname);
    await prefs.setString(_tokenKey, token);

  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullnameKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }


  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
  }
}