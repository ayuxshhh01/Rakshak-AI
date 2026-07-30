import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'api/api_service.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/location_bloc.dart';
import 'bloc/dashboard_bloc.dart';
import 'bloc/voice_sos_bloc.dart';
import 'bloc/trusted_circle_bloc.dart';
import 'bloc/safe_route_bloc.dart';
import 'bloc/safety_features_bloc.dart';
import 'screens/auth_screen.dart';
import 'screens/main_hub_screen.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(apiService: ApiService())
            ..add(CheckAuthStatus()),
        ),
        BlocProvider(
          create: (context) => LocationBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => DashboardBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => VoiceSosBloc(apiService: ApiService()),
        ),
        // New Safety Features BLoCs
        BlocProvider(
          create: (context) => TrustedCircleBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => SafeRouteBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => CheckInBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => AreaSafetyBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => EmergencyNumberBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => EmergencyPhraseBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => IncidentReportBloc(apiService: ApiService()),
        ),
      ],
      child: const TouristSafetyApp(),
    ),
  );
}

class TouristSafetyApp extends StatelessWidget {
  const TouristSafetyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Tourist Safety',
      theme: _buildModernTheme(),
      debugShowCheckedModeBanner: false,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const MainHubScreen();
          }
          if (state is AuthUnauthenticated || state is AuthFailure) {
            return const AuthScreen();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  ThemeData _buildModernTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF006B5E),
        brightness: Brightness.light,
        primary: const Color(0xFF006B5E),
        secondary: const Color(0xFFE8753F),
        tertiary: const Color(0xFFC4A000),
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFFAF9F6),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAF9F6),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1F36),
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006B5E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 4,
          shadowColor: const Color(0xFF006B5E).withOpacity(0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF006B5E),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF006B5E), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFFAFAFAF), fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(color: Color(0xFF006B5E), fontWeight: FontWeight.w600),
        prefixIconColor: const Color(0xFF006B5E),
      ),
    );
  }
}

