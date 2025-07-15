import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_tracker/storage/user_dto.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true, // Reset storage on unhandled errors
    ),
  );
  static const _keyToken = 'auth_token';

  // Save user data and token after login
  static Future<void> saveUser(
      int userId,
      String email,
      String fullname,
      // String firstname,
      // String lastname,
      {
        String? token,
      }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setInt('userId', userId),
        prefs.setString('email', email),
        prefs.setString('fullname', fullname),
        // prefs.setString('firstname', firstname),
        // prefs.setString('lastname', lastname),
        if (token != null) _storage.write(key: _keyToken, value: token),
      ]);
      await prefs.setInt('loginTime', DateTime.now().millisecondsSinceEpoch);
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

  // Check if the user is logged in (i.e., token exists)
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null;
    } catch (e) {
      print('Error checking login status: $e');
      await clearAll();
      return false;
    }
  }

  // Retrieve user data
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('userId');
    } catch (e) {
      print('Error reading user ID: $e');
      await clearAll();
      return null;
    }
  }

  static Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('email');
    } catch (e) {
      print('Error reading email: $e');
      await clearAll();
      return null;
    }
  }

  static Future<String?> getFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fullname');
    } catch (e) {
      print('Error reading fullname: $e');
      await clearAll();
      return null;
    }
  }


  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final int? userId = prefs.getInt('userId');
      final String? email = prefs.getString('email');
      final String? fullname = prefs.getString('fullname');
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


  // static Future<String?> getFirstName() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getString('firstname');
  //   } catch (e) {
  //     print('Error reading firstname: $e');
  //     await clearAll();
  //     return null;
  //   }
  // }

  // static Future<String?> getLastName() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getString('lastname');
  //   } catch (e) {
  //     print('Error reading lastname: $e');
  //     await clearAll();
  //     return null;
  //   }
  // }

  // Clear all user data and token on logout or error
  static Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _storage.delete(key: _keyToken);
    } catch (e) {
      print('Error clearing user data: $e');
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

  // static Future<void> saveMatchUserCount(int matchUser) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setInt('matchUser', matchUser);
  //   } catch (e) {
  //     print('Error saving match user count: $e');
  //     rethrow;
  //   }
  // }
  //
  // static Future<int?> getMatchUserCount() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getInt('matchUser');
  //   } catch (e) {
  //     print('Error reading match user count: $e');
  //     return null;
  //   }
  // }
  //
  // static Future<void> saveMatchedUsers(List<UserDto> users) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     List<String> userJsonList =
  //     users.map((user) => jsonEncode(user.toJson())).toList();
  //     await prefs.setStringList('matchedUsers', userJsonList);
  //   } catch (e) {
  //     print('Error saving matched users: $e');
  //     rethrow;
  //   }
  // }
  //
  // static Future<List<UserDto>> getMatchedUsers() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     List<String>? userJsonList = prefs.getStringList('matchedUsers');
  //     if (userJsonList == null) return [];
  //     return userJsonList
  //         .map((jsonStr) => UserDto.fromJson(jsonDecode(jsonStr)))
  //         .toList();
  //   } catch (e) {
  //     print('Error reading matched users: $e');
  //     return [];
  //   }
  // }

  static Future<void> isCheckedInfoSave(bool isChecked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isChecked', isChecked);
    } catch (e) {
      print('Error saving matched users: $e');
      rethrow;
    }
  }

  static Future<bool?> isCheckedInfoGet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isChecked');
    } catch (e) {
      print('Error reading match user count: $e');
      return null;
    }
  }
}
