import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../api/user_model.dart'; // Make sure you have this import for the User model
import 'digital_id_screen.dart';

// --- UI Color and Style Constants (for consistency) ---
const Color primaryTeal = Color(0xFF006B5E);
const Color secondaryOrange = Color(0xFFE8753F);
const Color backgroundLight = Color(0xFFFAF9F6);
const Color darkTextColor = Color(0xFF1A1F36);
const Color lightGreyText = Color(0xFF757575);
const Color cardColor = Colors.white;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isFamilyTrackingEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }

          final user = state.user;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 36),
              _buildProfileTile(
                icon: Icons.qr_code_rounded,
                title: 'Digital ID',
                subtitle: 'Show QR code for verification',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DigitalIdScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileTile(
                icon: Icons.phone_rounded,
                title: 'Emergency Contact',
                subtitle: user.emergencyContact.isNotEmpty ? user.emergencyContact : 'Not set',
              ),
              const SizedBox(height: 12),
              _buildProfileTile(
                icon: Icons.location_history_rounded,
                title: 'Location Sharing',
                subtitle: _isFamilyTrackingEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: _isFamilyTrackingEnabled,
                  onChanged: (newValue) {
                    setState(() => _isFamilyTrackingEnabled = newValue);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(newValue ? 'Location sharing enabled' : 'Location sharing disabled'),
                          backgroundColor: newValue ? primaryTeal : Colors.grey[600],
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                  },
                  activeColor: primaryTeal,
                  activeTrackColor: primaryTeal.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: Colors.red.shade500.withOpacity(0.3),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // --- Helper Widget for the Profile Header ---
  Widget _buildProfileHeader(user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : 'T',
                style: const TextStyle(fontSize: 56, color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Traveler ID: T${user.id.toString().padLeft(6, '0')}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for Profile Tiles ---
  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryTeal, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: lightGreyText, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: lightGreyText, size: 24) : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}