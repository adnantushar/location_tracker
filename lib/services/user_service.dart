import 'package:location_tracker/data/repositories/auth_repository.dart';
import 'package:location_tracker/storage/user_storage.dart';

import '../data/models/user.dart';
// import '../data/repositories/password_repository.dart';

class UserService {
  final AuthRepository _userRepository = AuthRepository();
  // final PasswordRepository _passwordRepository = PasswordRepository();

  Future<User> fetchUser() async {
    try {
      int? userId = await UserStorage.getUserId();
      if (userId != null) {
        final user = await _userRepository.getUser(userId);
        return user;
      } else {
        throw Exception('User ID not found in storage.');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  Future<User> fetchUserInfo(int userId) async {
    try {
      if (userId != 0) {
        final user = await _userRepository.getUser(userId);
        return user;
      } else {
        throw Exception('User ID not found in storage.');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  Future<List<User>> fetchUsers() async {
    try {
      List<User> users = await _userRepository.getAllUsers();
      if (!users.isEmpty) {
        return users;
      } else {
        throw Exception('Users are empty.');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  // Future<User> updateUser(User user) async {
  //   try {
  //     final updatedUser = await _userRepository.updateUser(user);
  //     return updatedUser;
  //   } catch (e) {
  //     throw Exception('Failed to update user: $e');
  //   }
  // }

  // Future<void> changePassword({
  //   required int userId,
  //   required String currentPassword,
  //   required String newPassword,
  //   required String newPasswordConfirmation,
  // }) async {
  //   try {
  //     return await _passwordRepository.changePassword(
  //       userId,
  //       currentPassword,
  //       newPassword,
  //       newPasswordConfirmation,
  //     );
  //   } catch (e) {
  //     throw Exception('Failed to change user password: $e');
  //   }
  // }
}