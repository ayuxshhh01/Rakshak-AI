import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../api/user_model.dart'; // Import the user model

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc({required this.apiService}) : super(AuthInitial()) {
    on<CheckAuthStatus>((event, emit) async {
      final user = await apiService.getUserProfile();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await apiService.login(event.username, event.password);
      if (result['success']) {
        // The result['user'] is now a strongly-typed UserModel
        emit(AuthAuthenticated(user: result['user']));
      } else {
        emit(AuthFailure(error: result['message'] ?? 'Login failed.'));
      }
    });

    // RegisterRequested and LogoutRequested remain the same
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await apiService.register(
        event.username,
        event.password,
        event.phone,
        event.emergencyContact,
      );
      if (result['success']) {
        emit(AuthUnauthenticated(message: 'Registration successful! Please log in.'));
      } else {
        emit(AuthFailure(error: result['message'] ?? 'Registration failed. Please try again.'));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await apiService.logout();
      emit(AuthUnauthenticated());
    });
  }
}

