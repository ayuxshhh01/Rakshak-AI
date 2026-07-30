import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital ID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1F36),
        scrolledUnderElevation: 0,
      ),
      backgroundColor: const Color(0xFFFAF9F6),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006B5E)),
            );
          }

          final digitalIdData = state.user.digitalId;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gradient Background Card
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF006B5E),
                          const Color(0xFF006B5E).withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF006B5E).withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 200,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  const Text(
                    'Your Traveler ID',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1F36),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Present this code to authorities for secure verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // ID Data Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                    ),
                    child: SelectableText(
                      digitalIdData,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF006B5E),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006B5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: const Color(0xFF006B5E).withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
