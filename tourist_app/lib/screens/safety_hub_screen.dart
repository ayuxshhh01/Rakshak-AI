import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/location_bloc.dart';
import '../bloc/safety_features_bloc.dart';
import 'emergency_contacts_screen.dart';
import 'emergency_services_screen.dart';
import 'medical_facilities_screen.dart';
import 'health_requirements_screen.dart';
import 'trusted_circle_screen.dart';
import 'safety_features_screens.dart';

// --- UI Color and Style Constants from other screens ---
const Color primaryTeal = Color(0xFF006B5E);
const Color secondaryOrange = Color(0xFFE8753F);
const Color darkTextColor = Color(0xFF1A1F36);
const Color lightGreyText = Color(0xFF757575);
const Color cardColor = Colors.white;
const Color backgroundLight = Color(0xFFFAF9F6);

class SafetyHubScreen extends StatefulWidget {
  const SafetyHubScreen({Key? key}) : super(key: key);
  @override
  _SafetyHubScreenState createState() => _SafetyHubScreenState();
}

class _SafetyHubScreenState extends State<SafetyHubScreen> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Circle> _geoFences = {};
  bool _isInUnsafeZone = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGeoFences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchGeoFences() async {
    try {
      final apiService = context.read<AuthBloc>().apiService;
      final zones = await apiService.getGeoFences();
      final circles = zones.map((zone) {
        return Circle(
          circleId: CircleId(zone['id'].toString()),
          center: LatLng(zone['center_lat'], zone['center_lon']),
          radius: (zone['radius_km'] as num).toDouble() * 1000,
          fillColor: Colors.red.withOpacity(0.2),
          strokeColor: Colors.red.shade400,
          strokeWidth: 2,
        );
      }).toSet();

      if (mounted) {
        setState(() => _geoFences = circles);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load safety zones.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _checkIfInUnsafeZone(Position position) {
    bool isInside = false;
    for (var fence in _geoFences) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        fence.center.latitude,
        fence.center.longitude,
      );
      if (distance <= fence.radius) {
        isInside = true;
        break;
      }
    }
    if (mounted && _isInUnsafeZone != isInside) {
      setState(() {
        _isInUnsafeZone = isInside;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Safety Hub', style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal,
          unselectedLabelColor: lightGreyText,
          indicatorColor: primaryTeal,
          tabs: const [
            Tab(text: 'Map & SOS'),
            Tab(text: 'Safety Features'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMapTab(),
          _buildFeaturesTab(),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return BlocConsumer<LocationBloc, LocationState>(
      listener: (context, state) async {
        if (state is LocationAcquired) {
          final controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(state.position.latitude, state.position.longitude), zoom: 14.0)
          ));
          _checkIfInUnsafeZone(state.position);
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(17.6599, 75.9064), zoom: 12.0),
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) _mapController.complete(controller);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              circles: _geoFences,
              padding: const EdgeInsets.only(bottom: 220),
            ),
            _buildSafetyStatusBanner(),
            _buildBottomActionPanel(),
          ],
        );
      },
    );
  }

  Widget _buildFeaturesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        const Text('New Safety Features', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: darkTextColor)),
        const SizedBox(height: 20),
        
        // 1. Trusted Circle
        _buildFeatureCard(
          icon: Icons.people_rounded,
          title: 'Trusted Circle',
          subtitle: 'Share location with family',
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrustedCircleScreen())),
        ),
        
        // 2. Safe Routes
        _buildFeatureCard(
          icon: Icons.directions_rounded,
          title: 'Safe Routes',
          subtitle: 'Navigate safely',
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafeRoutesScreen())),
        ),
        
        // 3. Check-In
        _buildFeatureCard(
          icon: Icons.check_circle_rounded,
          title: 'Check-In',
          subtitle: 'Proof of life status',
          color: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen())),
        ),
        
        // 4. Area Safety
        _buildFeatureCard(
          icon: Icons.bar_chart_rounded,
          title: 'Area Safety',
          subtitle: 'Crime rates & safety rating',
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AreaSafetyScreen())),
        ),
        
        // 5. Emergency Services
        _buildFeatureCard(
          icon: Icons.emergency_rounded,
          title: 'Emergency Services',
          subtitle: 'Nearby police, fire, ambulance',
          color: Colors.red.shade600,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyServicesScreen())),
        ),
        
        // 6. Emergency Numbers
        _buildFeatureCard(
          icon: Icons.phone_rounded,
          title: 'Emergency Contacts',
          subtitle: 'Quick emergency phone numbers',
          color: Colors.red,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyNumbersScreen())),
        ),
        
        // 7. Emergency Phrases
        _buildFeatureCard(
          icon: Icons.translate_rounded,
          title: 'Phrases',
          subtitle: 'Emergency phrases offline',
          color: Colors.indigo,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyPhrasesScreen())),
        ),
        
        // 8. Incident Report
        _buildFeatureCard(
          icon: Icons.warning_rounded,
          title: 'Report',
          subtitle: 'Report community incidents',
          color: Colors.deepOrange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentReportScreen())),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(color: lightGreyText, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: lightGreyText, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSafetyStatusBanner() {
    final bannerColor = _isInUnsafeZone ? const Color(0xFFC65321) : primaryTeal;
    final bannerText = _isInUnsafeZone ? "⚠️ Unsafe Zone Detected" : "✓ Safety Status: All Clear";
    final bannerIcon = _isInUnsafeZone ? Icons.warning_rounded : Icons.check_circle_rounded;

    return Positioned(
      top: 16,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(bannerIcon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              bannerText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 28, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 25,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SosButton(),
            const SizedBox(height: 28),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmergencyContactButton(
                  icon: Icons.local_police_rounded,
                  label: "Police\n100",
                  onPressed: () => _makePhoneCall('100'),
                  color: Colors.red.shade500,
                ),
                _buildEmergencyContactButton(
                  icon: Icons.health_and_safety_rounded,
                  label: "Medical\n102",
                  onPressed: () => _makePhoneCall('102'),
                  color: Colors.orange.shade500,
                ),
              ],
            ),
            
            const SizedBox(height: 28),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessButton(
                    icon: Icons.contacts_rounded,
                    label: 'Contacts',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessButton(
                    icon: Icons.local_hospital_rounded,
                    label: 'Medical',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicalFacilitiesScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessButton(
                    icon: Icons.vaccines_rounded,
                    label: 'Health',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HealthRequirementsScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal.withOpacity(0.1),
        foregroundColor: primaryTeal,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: primaryTeal),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: color.withOpacity(0.4),
          ),
          child: Icon(icon, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not call $phoneNumber')),
      );
    }
  }
}

// --- SosButton Widget (Unchanged) ---
class SosButton extends StatefulWidget {
  const SosButton({Key? key}) : super(key: key);
  @override
  _SosButtonState createState() => _SosButtonState();
}
class _SosButtonState extends State<SosButton> {
  double _progress = 0;
  Timer? _timer;
  bool _isAlertSent = false;
  bool _isPressed = false;

  void _startTimer(Position? currentPosition) {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acquiring GPS location... Please wait.'), backgroundColor: Colors.orange));
      return;
    }
    setState(() {
      _isAlertSent = false;
      _isPressed = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.01;
        if (_progress >= 1) {
          _timer?.cancel();
          _progress = 0;
          _sendAlert(currentPosition);
          _isPressed = false;
        }
      });
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _progress = 0;
      _isPressed = false;
    });
  }

  void _sendAlert(Position position) async {
    final success = await context.read<AuthBloc>().apiService.sendSosAlert(position.latitude, position.longitude);
    if (!mounted) return;

    if (success) {
      setState(() => _isAlertSent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Alert Sent! Help is on the way.'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send SOS. Check connection.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        final bool isLocationReady = state is LocationAcquired;
        final position = isLocationReady ? state.position : null;

        return GestureDetector(
          onLongPressStart: isLocationReady ? (_) => _startTimer(position) : null,
          onLongPressEnd: isLocationReady ? (_) => _cancelTimer() : null,
          child: Opacity(
            opacity: isLocationReady ? 1.0 : 0.5,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isPressed ? 140 : 150,
              height: _isPressed ? 140 : 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(value: _progress, strokeWidth: 10, backgroundColor: Colors.red.withOpacity(0.3), valueColor: const AlwaysStoppedAnimation<Color>(Colors.red)),
                  Center(
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)]),
                      child: Center(
                        child: _isAlertSent
                            ? const Icon(Icons.check, color: Colors.white, size: 60)
                            : const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}