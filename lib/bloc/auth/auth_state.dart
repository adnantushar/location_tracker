abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  final int? unreadCount;

  AuthSuccess(this.message, {this.unreadCount});
}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure({required this.error});
}