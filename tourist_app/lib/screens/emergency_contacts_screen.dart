import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../bloc/auth_bloc.dart';
import '../api/api_service.dart';
import '../api/user_model.dart';

const Color primaryTeal = Color(0xFF006B5E);
const Color secondaryOrange = Color(0xFFE8753F);
const Color backgroundLight = Color(0xFFFAF9F6);
const Color darkTextColor = Color(0xFF1A1F36);
const Color lightGreyText = Color(0xFF757575);
const Color cardColor = Colors.white;

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late ApiService apiService;
  UserModel? userProfile;
  List<Map<String, dynamic>> officialNumbers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadUserProfile();
    _loadEmergencyNumbers();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          userProfile = UserModel.fromJson(userData);
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadEmergencyNumbers() async {
    try {
      final numbers = await apiService.getEmergencyNumbers();
      if (numbers.isNotEmpty) {
        setState(() {
          officialNumbers = numbers
              .map((num) => {
                    'name': num['service_name'] ?? num['service_type'] ?? 'Service',
                    'phone': num['phone_number'] ?? '',
                    'icon': _getServiceIcon(num['service_type'] ?? '')
                  })
              .toList();
          isLoading = false;
        });
      } else {
        _loadDefaultEmergencyNumbers();
      }
    } catch (e) {
      print('Error loading emergency numbers: $e');
      _loadDefaultEmergencyNumbers();
    }
  }

  void _loadDefaultEmergencyNumbers() {
    setState(() {
      officialNumbers = [
        {'name': 'Police', 'phone': '100', 'icon': '🚔'},
        {'name': 'Medical Emergency', 'phone': '102', 'icon': '🚑'},
        {'name': 'Fire Department', 'phone': '101', 'icon': '🚒'},
        {'name': 'Tourist Helpline', 'phone': '1363', 'icon': '🎫'},
      ];
      isLoading = false;
    });
  }

  String _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'police':
        return '🚔';
      case 'ambulance':
        return '🚑';
      case 'fire':
        return '🚒';
      case 'hospital':
        return '🏥';
      case 'embassy':
        return '🏛️';
      case 'tourist police':
        return '🎫';
      default:
        return '📞';
    }
  }

  void _callPhoneNumber(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: primaryTeal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              children: [
                // Primary Emergency Contact Section
                const Text(
                  'Primary Emergency Contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkTextColor),
                ),
                const SizedBox(height: 16),
                if (userProfile != null && userProfile!.emergencyContact.isNotEmpty)
                  _buildContactTile(
                    {
                      'name': 'Primary Contact',
                      'phone': userProfile!.emergencyContact,
                      'icon': '🆘',
                    },
                    Colors.red.shade600,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange, width: 1.5),
                    ),
                    child: const Text(
                      'No emergency contact set. Please set one in your profile.',
                      style: TextStyle(color: darkTextColor, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 36),

                // Official Emergency Numbers
                const Text(
                  'Emergency Services',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkTextColor),
                ),
                const SizedBox(height: 16),
                if (officialNumbers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Loading emergency numbers...', style: TextStyle(color: lightGreyText)),
                  )
                else
                  ...officialNumbers.map((service) => _buildContactTile(service, Colors.red.shade500)).toList(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildContactTile(Map<String, dynamic> contact, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(contact['icon']!, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(
          contact['name']!,
          style: const TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 16),
        ),
        subtitle: Text(
          contact['phone']!,
          style: const TextStyle(color: lightGreyText, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _callPhoneNumber(contact['phone']!),
          icon: const Icon(Icons.call_rounded, size: 18),
          label: const Text('Call'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}
