part of 'auth_bloc.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

// --- THIS IS THE FIX ---
// The AuthAuthenticated state now correctly defines a 'user' property,
// which will resolve the error in your ProfileScreen.
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {
  final String? message;
  AuthUnauthenticated({this.message});
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure({required this.error});
}
