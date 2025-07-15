import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_tracker/storage/user_dto.dart';

class AdminUserStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true, // Reset storage on unhandled errors
    ),
  );
  static const _keyToken = 'admin_auth_token';

  // Save user data and token after login
  static Future<void> saveUser(int adminUserId,
      String adminEmail,
      String adminFullname,
      // String firstname,
      // String lastname,
          {
        String? token,
      }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setInt('adminUserId', adminUserId),
        prefs.setString('adminEmail', adminEmail),
        prefs.setString('adminFullname', adminFullname),
        // prefs.setString('firstname', firstname),
        // prefs.setString('lastname', lastname),
        if (token != null) _storage.write(key: _keyToken, value: token),
      ]);
      await prefs.setInt('loginTime', DateTime
          .now()
          .millisecondsSinceEpoch);
      if (token != null) await prefs.setString('authToken', token);
    } catch (e) {
      print('Error saving user to secure storage: $e');
      await clearAll();
      rethrow;
    }
  }

  // Retrieve the authentication token
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _keyToken);
    } catch (e) {
      print('Error reading token: $e');
      await clearAll();
      return null;
    }
  }
  // Retrieve user data
  static Future<int?> getAdminUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('adminUserId');
    } catch (e) {
      print('Error reading user ID: $e');
      await clearAll();
      return null;
    }
  }

  static Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('adminEmail');
    } catch (e) {
      print('Error reading email: $e');
      await clearAll();
      return null;
    }
  }

  static Future<String?> getFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('adminFullname');
    } catch (e) {
      print('Error reading fullname: $e');
      await clearAll();
      return null;
    }
  }


  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final int? userId = prefs.getInt('adminUserId');
      final String? email = prefs.getString('adminEmail');
      final String? fullname = prefs.getString('adminFullname');
      final String? token = await _storage.read(key: _keyToken);

      if (userId != null && email != null && fullname != null) {
        return UserModel.fromStorage(
          userId: userId,
          email: email,
          fullname: fullname,
          token: token,
        );
      } else {
        return null; // incomplete data
      }
    } catch (e) {
      print('Error retrieving user: $e');
      return null;
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _storage.deleteAll();
    } catch (e) {
      print('Error clearing all storage: $e');
    }
  }
}