import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_tracker/data/repositories/auth_repository.dart';
import 'package:location_tracker/storage/admin_user_storage.dart';
import 'package:location_tracker/storage/user_storage.dart';
import 'package:location_tracker/storage/secure_storage.dart';
import 'package:location_tracker/bloc/auth/auth_event.dart';
import 'package:location_tracker/bloc/auth/auth_state.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()){
    on<RegisterEvent>(_onRegister);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckLoginStatusEvent>(_onCheckLoginStatus);
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.register(event.user);

      if (response['success'] == false) {
        final String errorMessage =
            response['message'] ?? 'Registration failed';
        final errors = response['errors'] as Map<String, dynamic>?;

        String detailedError = errorMessage;
        if (errors != null && errors.isNotEmpty) {
          detailedError = errors.entries
              .map(
                (entry) => entry.value is List ? entry.value[0] : entry.value,
          )
              .join(', ');
        }
        throw Exception(detailedError);
      }

      var userInfo = response['user'];
      final token = response['token'];
      final userId = userInfo['id'] ?? -1;
      final email = userInfo['email'];
      final fullname = userInfo['fullname'];

      if (userId == -1) {
        throw Exception("Invalid user ID received from the server.");
      }

      await UserStorage.saveUser(userId, email, fullname, token);
      emit(AuthSuccess(response['Message'] ?? 'User registered successfully!'));
    } catch (e) {
      emit(AuthFailure(error: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    String msg = '';

    try {
      // Perform login
      final response = await _authRepository.login(event.email, event.password);

      var userInfo = response['user'];
      msg = response['message'];
      final token = response['token']; // Use proper token if available
      var adminInfo = response['admin'];

      final userId = userInfo['id'] ?? -1;
      final email = userInfo['email'];
      final fullname = userInfo['fullname'];

      final adminUserId = adminInfo['id'] ?? -1;
      final adminEmail =  adminInfo['email'];
      final adminName = adminInfo['fullname'];


      if (userId == -1) {
        throw Exception("Invalid user ID received from the server.");
      }

      // Save user data
      try {
        await SecureStorage.saveUser(
          userId,
          email,
          fullname,
          token: token,
        );
      } catch (e) {
        print('SecureStorage save failed: $e');
        await SecureStorage.clearAll();
        throw Exception('Failed to save user data. Please try again.');
      }

      // Save admin data
      try {
        await AdminUserStorage.saveUser(
          adminUserId,
          adminEmail,
          adminName,
          token: null,
        );
      } catch (e) {
        print('Admin User save failed: $e');
        await SecureStorage.clearAll();
        await AdminUserStorage.clearAll();
        throw Exception('Failed to save user data. Please try again.');
      }

      // Fetch unread messages and notify
      int unreadCount = 0;
      // try {
      //   final unreadMessages = await _messageService.getUnreadMessages(userId);
      //   unreadCount = unreadMessages.length;
      //
      //   for (var message in unreadMessages) {
      //     final receiverInfo = await _authRepository.getUser(message.senderId);
      //     await ForegroundMessageNotificationService.showLocalNotification(
      //       title: '${receiverInfo.fullname} Sent a Message',
      //       body: message.content,
      //       payload: jsonEncode({
      //         'senderId': message.senderId.toString(),
      //         'receiverId': message.receiverId.toString(),
      //       }),
      //     );
      //   }
      // } catch (e) {
      //   print('Failed to fetch unread messages: $e');
      //   // Continue login even if fetching messages fails
      // }

      emit(
        AuthSuccess(
          response['Message'] ?? 'ログインが完了しました。',
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(
        AuthFailure(
          error:
          msg.isNotEmpty
              ? msg
              : e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCheckLoginStatus(
      CheckLoginStatusEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await SecureStorage.isLoggedIn();
      if (isLoggedIn) {
        // final userId = await SecureStorage.getUserId();
        final token = await SecureStorage.getToken();
        // if (userId != null) {
        //   emit(AuthSuccess(''));
        // }
        if (token != null) {
          final valid = await _authRepository.validateToken(token);
          if (valid) {
            emit(AuthSuccess(''));
          } else {
            await SecureStorage.clearAll();
            await UserStorage.clearUser();
            await AdminUserStorage.clearAll();
            emit(AuthInitial());
          }
        }
        else {
          await SecureStorage.clearAll();
          await UserStorage.clearUser();
          await AdminUserStorage.clearAll();
          emit(AuthInitial());
        }
      } else {
        await SecureStorage.clearAll();
        await AdminUserStorage.clearAll();
        emit(AuthInitial());
      }
    } catch (e) {
      print('Error checking login status: $e');
      await SecureStorage.clearAll();
      await AdminUserStorage.clearAll();
      emit(AuthInitial());
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await UserStorage.clearUser();
      await SecureStorage.clearAll();
      await AdminUserStorage.clearAll();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(error: 'Logout failed: $e'));
    }
  }
}