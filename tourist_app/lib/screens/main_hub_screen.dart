import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/location_bloc.dart';
import '../bloc/voice_sos_bloc.dart'; // 1. Add this import
import 'home_screen.dart';
import 'safety_hub_screen.dart';
import 'profile_screen.dart';

class MainHubScreen extends StatefulWidget {
  const MainHubScreen({Key? key}) : super(key: key);

  @override
  _MainHubScreenState createState() => _MainHubScreenState();
}

class _MainHubScreenState extends State<MainHubScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // When the user logs in and this screen is loaded,
    // we immediately tell our BLoCs to start their background work.
    context.read<LocationBloc>().add(StartLocationTracking());
    // --- 2. ALSO, START LISTENING FOR THE VOICE KEYWORD ---
    context.read<VoiceSosBloc>().add(StartListening());
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const SafetyHubScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF006B5E),
          unselectedItemColor: const Color(0xFFBDBDBD),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              activeIcon: Icon(Icons.home_rounded, size: 26),
              label: 'Journey',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.security_outlined, size: 26),
              activeIcon: Icon(Icons.security_rounded, size: 26),
              label: 'Safety',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

