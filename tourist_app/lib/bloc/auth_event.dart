part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

/// Event triggered when the user attempts to log in.
class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  LoginRequested({required this.username, required this.password});
}

/// Event triggered when a new user registers.
class RegisterRequested extends AuthEvent {
  final String username;
  final String password;
  final String phone;
  final String emergencyContact;

  RegisterRequested({
    required this.username,
    required this.password,
    required this.phone,
    required this.emergencyContact,
  });
}

/// Event triggered when the user logs out.
class LogoutRequested extends AuthEvent {}

/// Event triggered on app startup to check for a stored token.
class CheckAuthStatus extends AuthEvent {}

