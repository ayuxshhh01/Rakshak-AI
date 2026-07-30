import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/safety_features_bloc.dart';
import '../bloc/safe_route_bloc.dart';
import '../api/api_service.dart';

const Color primaryTeal = Color(0xFF006B5E);
const Color backgroundLight = Color(0xFFFAF9F6);
const Color darkText = Color(0xFF1A1F36);
const Color lightGrey = Color(0xFF757575);

// ============= SAFE ROUTES SCREEN =============
class SafeRoutesScreen extends StatefulWidget {
  const SafeRoutesScreen({Key? key}) : super(key: key);

  @override
  State<SafeRoutesScreen> createState() => _SafeRoutesScreenState();
}

class _SafeRoutesScreenState extends State<SafeRoutesScreen> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> safeRoutes = [];
  bool isLoading = false;
  String? errorMessage;
  double? currentLat;
  double? currentLon;

  @override
  void initState() {
    super.initState();
    _loadSafeRoutesFromItinerary();
  }

  Future<void> _loadSafeRoutesFromItinerary() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get user's current location for display context
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
        );
        currentLat = position.latitude;
        currentLon = position.longitude;
      } catch (e) {
        // Location permission not available, use defaults
        currentLat = 28.7041;
        currentLon = 77.1025;
      }

      // Fetch safe routes from user's itinerary
      // Backend will automatically fetch itinerary from authenticated user
      final response = await _apiService.getSafeRoutesFromItinerary();

      setState(() {
        // Handle both list and dict responses
        if (response is List) {
          safeRoutes = response.map((r) => Map<String, dynamic>.from(r)).toList();
        } else if (response is Map && response.containsKey('routes')) {
          safeRoutes = (response['routes'] as List?)
              ?.map((r) => Map<String, dynamic>.from(r))
              .toList() ?? [];
        } else {
          safeRoutes = [];
        }
        
        isLoading = false;

        if (safeRoutes.isEmpty) {
          errorMessage = 'No routes from itinerary. Create an itinerary first.';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      print('🚨 Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(
          title: const Text('Safe Routes', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    // Handle error state
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(
          title: const Text('Safe Routes', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(fontSize: 16, color: darkText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadSafeRoutesFromItinerary,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Safe Routes', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSafeRoutesFromItinerary,
        color: primaryTeal,
        child: safeRoutes.isEmpty
            ? Center(
                child: Text(
                  'No safe routes available',
                  style: const TextStyle(color: lightGrey, fontSize: 16),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ...safeRoutes.map((route) => _buildRouteCard(route)),
                ],
              ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final safetyScore = route['safety_score'] ?? 85;
    final safetyColor = safetyScore > 80 ? Colors.green : safetyScore > 60 ? Colors.orange : Colors.red;
    final distance = route['distance_km'] ?? 0;
    final time = route['estimated_time_minutes'] ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    route['route_name'] ?? 'Route',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: safetyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Safety: $safetyScore%',
                    style: TextStyle(color: safetyColor, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.directions_walk, color: lightGrey, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${distance.toStringAsFixed(2)} km • ${time.toInt()} min',
                  style: const TextStyle(color: lightGrey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Extract coordinates from route
                  final startLoc = route['start_location'] as Map?;
                  final endLoc = route['end_location'] as Map?;
                  
                  if (startLoc == null || endLoc == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Route coordinates not available'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  final startLat = startLoc['lat'] ?? 0.0;
                  final startLon = startLoc['lon'] ?? 0.0;
                  final endLat = endLoc['lat'] ?? 0.0;
                  final endLon = endLoc['lon'] ?? 0.0;
                  
                  // Build Google Maps URL
                  final String url = 'https://www.google.com/maps/dir/?api=1'
                      '&origin=$startLat,$startLon'
                      '&destination=$endLat,$endLon';
                  
                  try {
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Could not open Google Maps'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error opening maps: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('View Route'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= CHECK-IN SCREEN =============
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({Key? key}) : super(key: key);

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _selectedStatus = 'Safe';
  String _selectedVisibility = 'Trusted Circle';
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CheckInBloc>().add(const FetchCheckIns());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Check-In', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<CheckInBloc, CheckInState>(
        listener: (context, state) {
          if (state is CheckInLoaded) {
            _noteController.clear();
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create Check-In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkText)),
                      const SizedBox(height: 16),
                      const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: darkText)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Safe', label: Text('Safe')),
                          ButtonSegment(value: 'Moderate Risk', label: Text('Moderate')),
                          ButtonSegment(value: 'Need Help', label: Text('Help')),
                        ],
                        selected: {_selectedStatus},
                        onSelectionChanged: (v) => setState(() => _selectedStatus = v.first),
                      ),
                      const SizedBox(height: 16),
                      const Text('Visibility', style: TextStyle(fontWeight: FontWeight.w600, color: darkText)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _selectedVisibility,
                        onChanged: (v) => setState(() => _selectedVisibility = v ?? 'Trusted Circle'),
                        items: ['Public', 'Trusted Circle', 'Private']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add a note (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state is CheckInLoading ? null : _createCheckIn,
                          style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                          child: Text(
                            state is CheckInLoading ? 'Creating...' : 'Create Check-In',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Your Check-Ins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkText)),
              const SizedBox(height: 16),
              if (state is CheckInLoaded)
                ...state.checkIns.map((checkIn) => _buildCheckInCard(checkIn))
              else
                const Text('No check-ins yet', style: TextStyle(color: lightGrey)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckInCard(Map<String, dynamic> checkIn) {
    final statusColor = checkIn['status'] == 'Safe' ? Colors.green : Colors.orange;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            checkIn['status'] == 'Safe' ? Icons.check_circle : Icons.info,
            color: statusColor,
          ),
        ),
        title: Text(checkIn['location_name'] ?? 'Location', style: const TextStyle(fontWeight: FontWeight.w700, color: darkText)),
        subtitle: Text(checkIn['status'] ?? 'Unknown', style: TextStyle(color: statusColor)),
      ),
    );
  }

  void _createCheckIn() {
    context.read<CheckInBloc>().add(
      CreateCheckIn(
        lat: 0.0, lon: 0.0,
        locationName: 'Current Location',
        status: _selectedStatus,
        note: _noteController.text,
        visibility: _selectedVisibility,
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

// ============= AREA SAFETY SCREEN =============
class AreaSafetyScreen extends StatefulWidget {
  const AreaSafetyScreen({Key? key}) : super(key: key);

  @override
  State<AreaSafetyScreen> createState() => _AreaSafetyScreenState();
}

class _AreaSafetyScreenState extends State<AreaSafetyScreen> {
  final ApiService _apiService = ApiService();
  
  // Real-time data state
  Map<String, dynamic>? safetyData;
  bool isLoading = false;
  String? errorMessage;
  double? currentLat;
  double? currentLon;
  String? currentCity;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchSafety();
  }

  Future<void> _getCurrentLocationAndFetchSafety() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // CHECK AND REQUEST LOCATION PERMISSION
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isLoading = false;
            errorMessage = '❌ Location permission is required to get your area safety information';
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isLoading = false;
          errorMessage = '❌ Location permission is permanently denied. Please enable it in app settings.';
        });
        return;
      }

      // Get user's current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );

      currentLat = position.latitude;
      currentLon = position.longitude;
      print('📍 Current Location: $currentLat, $currentLon');

      // Fetch real safety data from API with real-time crime statistics
      final response = await _apiService.getAreaSafety(
        latitude: currentLat!,
        longitude: currentLon!,
      );

      setState(() {
        safetyData = response;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching safety data: $e';
      });
      print('🚨 Error: $e');
    }
  }

  Color _getWarningColor(String? warningLevel) {
    switch (warningLevel?.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getWarningEmoji(String? warningLevel) {
    switch (warningLevel?.toUpperCase()) {
      case 'HIGH':
        return '⚠️';
      case 'MEDIUM':
        return '⚡';
      case 'LOW':
        return '✅';
      default:
        return 'ℹ️';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(
          title: const Text('Area Safety', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: primaryTeal),
        ),
      );
    }

    // Handle error state
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(
          title: const Text('Area Safety', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(fontSize: 16, color: darkText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _getCurrentLocationAndFetchSafety,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // Handle no data state
    if (safetyData == null) {
      return Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(
          title: const Text('Area Safety', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        body: const Center(
          child: Text('No safety data available', style: TextStyle(color: lightGrey)),
        ),
      );
    }

    final safetyScore = (safetyData!['safety_score'] ?? 0).toInt();
    final warningLevel = safetyData!['warning_level'] ?? 'UNKNOWN';
    final crimeRate = safetyData!['crime_rate'] ?? 0;
    final recentIncidents = safetyData!['recent_incidents'] ?? 0;
    final sources = safetyData!['sources'] ?? [];
    final lastUpdated = safetyData!['last_updated'] ?? 'Unknown';

    final warningColor = _getWarningColor(warningLevel);
    final warningEmoji = _getWarningEmoji(warningLevel);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Area Safety', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _getCurrentLocationAndFetchSafety,
        color: primaryTeal,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Safety Score Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: warningColor,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '$warningEmoji Area Safety',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$safetyScore/100',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      warningLevel,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Safety Metrics
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMetricRow(
                      icon: Icons.warning_rounded,
                      label: 'Crime Rate',
                      value: '$crimeRate incidents per 1000 people',
                    ),
                    const Divider(),
                    _buildMetricRow(
                      icon: Icons.report_problem_rounded,
                      label: 'Recent Incidents',
                      value: '$recentIncidents reported in this area',
                    ),
                  ],
                ),
              ),
            ),

            // Data Sources
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Sources',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var source in sources)
                          Chip(
                            label: Text(source),
                            backgroundColor: primaryTeal.withOpacity(0.2),
                            labelStyle: const TextStyle(color: primaryTeal, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Last Updated
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.update_rounded, color: primaryTeal),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Last Updated',
                          style: TextStyle(fontSize: 12, color: lightGrey),
                        ),
                        Text(
                          lastUpdated,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Safety Recommendations
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              color: warningColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safety Tips',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getSafetyRecommendation(warningLevel),
                      style: const TextStyle(fontSize: 13, color: darkText, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: primaryTeal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: lightGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSafetyRecommendation(String? warningLevel) {
    switch (warningLevel?.toUpperCase()) {
      case 'HIGH':
        return '⚠️ Crime Alert: Consider using official transportation and avoid traveling alone. Stay in well-lit, populated areas.';
      case 'MEDIUM':
        return '⚡ Caution: Stay alert, avoid unfamiliar areas after dark. Use official taxis or ride-sharing services.';
      case 'LOW':
        return '✅ Safe Zone: Area appears relatively safe. Normal precautions apply. Still be aware of your surroundings.';
      default:
        return 'Safety information is being analyzed. Check back shortly.';
    }
  }
}

// ============= EMERGENCY NUMBERS SCREEN =============
class EmergencyNumbersScreen extends StatefulWidget {
  const EmergencyNumbersScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyNumbersScreen> createState() => _EmergencyNumbersScreenState();
}

class _EmergencyNumbersScreenState extends State<EmergencyNumbersScreen> {
  String _selectedServiceType = 'Police';

  @override
  void initState() {
    super.initState();
    context.read<EmergencyNumberBloc>().add(
      FetchEmergencyNumbers(serviceType: _selectedServiceType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Emergency', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<EmergencyNumberBloc, EmergencyNumberState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Service Type', style: TextStyle(fontWeight: FontWeight.w600, color: darkText)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Police', 'Ambulance', 'Fire', 'Embassy']
                      .map((type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(type),
                              selected: _selectedServiceType == type,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedServiceType = type);
                                  context.read<EmergencyNumberBloc>().add(
                                    FetchEmergencyNumbers(serviceType: type),
                                  );
                                }
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              if (state is EmergencyNumberLoaded)
                ...state.numbers.map((number) => _buildNumberCard(number))
              else if (state is EmergencyNumberLoading)
                const Center(child: CircularProgressIndicator(color: primaryTeal))
              else
                const Text('No numbers found', style: TextStyle(color: lightGrey)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNumberCard(Map<String, dynamic> number) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.phone, color: primaryTeal, size: 28),
        title: Text(number['service_name'] ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w700, color: darkText)),
        subtitle: Text(number['phone_number'] ?? '', style: const TextStyle(color: lightGrey, fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: () {},
        ),
      ),
    );
  }
}

// ============= EMERGENCY PHRASES SCREEN =============
class EmergencyPhrasesScreen extends StatefulWidget {
  const EmergencyPhrasesScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyPhrasesScreen> createState() => _EmergencyPhrasesScreenState();
}

class _EmergencyPhrasesScreenState extends State<EmergencyPhrasesScreen> {
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    context.read<EmergencyPhraseBloc>().add(FetchEmergencyPhrases(_selectedLanguage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Emergency Phrases', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<EmergencyPhraseBloc, EmergencyPhraseState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Language', style: TextStyle(fontWeight: FontWeight.w600, color: darkText)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedLanguage,
                onChanged: (lang) {
                  if (lang != null) {
                    setState(() => _selectedLanguage = lang);
                    context.read<EmergencyPhraseBloc>().add(FetchEmergencyPhrases(lang));
                  }
                },
                items: ['English', 'Hindi', 'Spanish', 'French']
                    .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (state is EmergencyPhraseLoaded)
                ...state.phrases.map((phrase) => _buildPhraseCard(phrase))
              else if (state is EmergencyPhraseLoading)
                const Center(child: CircularProgressIndicator(color: primaryTeal))
              else
                const Text('No phrases found', style: TextStyle(color: lightGrey)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhraseCard(Map<String, dynamic> phrase) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(phrase['phrase_type'] ?? '', style: const TextStyle(color: primaryTeal, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            Text(phrase['english_text'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: darkText)),
            const SizedBox(height: 8),
            Text(phrase['local_text'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: primaryTeal)),
            if ((phrase['pronunciation'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Pronunciation: ${phrase['pronunciation']}', style: const TextStyle(color: lightGrey, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ============= INCIDENT REPORT SCREEN =============
class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({Key? key}) : super(key: key);

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String _selectedType = 'Theft';
  String _selectedSeverity = 'Medium';
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<IncidentReportBloc>().add(const FetchIncidentReports());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Incident Reports', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<IncidentReportBloc, IncidentReportState>(
        listener: (context, state) {
          if (state is IncidentReportLoaded) {
            _descriptionController.clear();
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Report Incident', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkText)),
                      const SizedBox(height: 16),
                      DropdownButton<String>(
                        value: _selectedType,
                        onChanged: (v) => setState(() => _selectedType = v ?? 'Theft'),
                        items: ['Theft', 'Assault', 'Scam', 'Harassment', 'Dangerous Area']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Low', label: Text('Low')),
                          ButtonSegment(value: 'Medium', label: Text('Medium')),
                          ButtonSegment(value: 'High', label: Text('High')),
                        ],
                        selected: {_selectedSeverity},
                        onSelectionChanged: (v) => setState(() => _selectedSeverity = v.first),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe what happened',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state is IncidentReportLoading ? null : _reportIncident,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text(
                            state is IncidentReportLoading ? 'Reporting...' : 'Submit Report',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Recent Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkText)),
              const SizedBox(height: 16),
              if (state is IncidentReportLoaded)
                ...state.reports.map((report) => _buildReportCard(report))
              else
                const Text('No reports yet', style: TextStyle(color: lightGrey)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final severityColor = report['severity'] == 'High' ? Colors.red : Colors.orange;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severityColor.withOpacity(0.2),
          child: Icon(Icons.warning, color: severityColor),
        ),
        title: Text(report['incident_type'] ?? 'Incident', style: const TextStyle(fontWeight: FontWeight.w700, color: darkText)),
        subtitle: Text(report['location_name'] ?? 'Location', style: const TextStyle(color: lightGrey)),
        trailing: Text('${report['helpful_count'] ?? 0}👍', style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  void _reportIncident() {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the incident'), backgroundColor: Colors.orange),
      );
      return;
    }

    context.read<IncidentReportBloc>().add(
      ReportIncident(
        lat: 0.0, lon: 0.0,
        locationName: 'Current Location',
        incidentType: _selectedType,
        description: _descriptionController.text,
        severity: _selectedSeverity,
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
