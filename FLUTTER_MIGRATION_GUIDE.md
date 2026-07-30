# Flutter: Migrate Safety Screens to Real-Time Data

## Overview

All Flutter safety feature screens need to be updated to call the new real-time API endpoints instead of using hardcoded/seeded demo data.

**Status**: API service updated ✅ | Screens pending update ⏳

---

## Prerequisites

✅ **Completed**:
- API service has 3 new methods:
  - `getMedicalFacilities(lat, lon, radius)` 
  - `getEmergencyServices(lat, lon, serviceType, radius)`
  - `getAreaSafety(lat, lon, city)`

⏳ **Pending**:
- Backend: Add `GOOGLE_MAPS_API_KEY` to Django settings.py
- Flutter screens: Update UI code to call these methods

---

## 1. Medical Facilities Screen

### File
`tourist_app/lib/screens/medical_facilities_screen.dart`

### Current Implementation (Hardcoded)
```dart
class MedicalFacilitiesScreen extends StatefulWidget {
  @override
  State<MedicalFacilitiesScreen> createState() => _MedicalFacilitiesScreenState();
}

class _MedicalFacilitiesScreenState extends State<MedicalFacilitiesScreen> {
  final List<Map<String, dynamic>> hardcodedFacilities = [
    {
      'name': 'Apollo Hospital',
      'type': 'Hospital',
      'distance': 1.2,
      'rating': 4.8,
      'address': '123 Main Street',
    },
    // ... more hardcoded data
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: hardcodedFacilities.length,
      itemBuilder: (context, index) {
        final facility = hardcodedFacilities[index];
        return ListTile(
          title: Text(facility['name']),
          subtitle: Text('${facility['distance']} km away'),
        );
      },
    );
  }
}
```

### Updated Implementation (Real-Time)
```dart
class MedicalFacilitiesScreen extends StatefulWidget {
  @override
  State<MedicalFacilitiesScreen> createState() => _MedicalFacilitiesScreenState();
}

class _MedicalFacilitiesScreenState extends State<MedicalFacilitiesScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> facilities = [];
  bool isLoading = false;
  String? errorMessage;
  double? currentLat;
  double? currentLon;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchFacilities();
  }

  Future<void> _getCurrentLocationAndFetchFacilities() async {
    try {
      setState(() => isLoading = true);

      // Get user's current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );

      currentLat = position.latitude;
      currentLon = position.longitude;

      // Fetch real medical facilities from API
      final response = await _apiService.getMedicalFacilities(
        latitude: currentLat!,
        longitude: currentLon!,
        radius: 5000, // 5 km radius
      );

      setState(() {
        facilities = List<Map<String, dynamic>>.from(response['facilities'] ?? []);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load facilities: $e';
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text('Error: $errorMessage'));
    }

    if (facilities.isEmpty) {
      return const Center(child: Text('No medical facilities found nearby'));
    }

    return RefreshIndicator(
      onRefresh: _getCurrentLocationAndFetchFacilities,
      child: ListView.builder(
        itemCount: facilities.length,
        itemBuilder: (context, index) {
          final facility = facilities[index];
          return ListTile(
            leading: Icon(
              facility['type'] == 'Hospital' ? Icons.local_hospital : Icons.medical_services,
              color: Colors.red,
            ),
            title: Text(facility['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${facility['type']}'),
                Text('Distance: ${(facility['distance'] as num).toStringAsFixed(2)} km'),
                if (facility['rating'] != null)
                  Text('Rating: ⭐ ${facility['rating']}'),
              ],
            ),
            onTap: () {
              // Show facility details
              _showFacilityDetails(facility);
            },
          );
        },
      ),
    );
  }

  void _showFacilityDetails(Map<String, dynamic> facility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(facility['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${facility['type']}'),
            Text('Address: ${facility['address'] ?? 'N/A'}'),
            Text('Distance: ${(facility['distance'] as num).toStringAsFixed(2)} km'),
            if (facility['rating'] != null)
              Text('Rating: ⭐ ${facility['rating']}'),
            if (facility['phone'] != null)
              Text('Phone: ${facility['phone']}'),
            if (facility['is_open'] != null)
              Text('Status: ${facility['is_open'] ? 'Open' : 'Closed'}'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Get Directions'),
            onPressed: () {
              // Launch Google Maps with directions
              final lat = facility['lat'];
              final lon = facility['lon'];
              final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}
```

### Key Changes:
- ✅ Removed hardcoded `hardcodedFacilities` list
- ✅ Added `_getCurrentLocationAndFetchFacilities()` method
- ✅ Calls `_apiService.getMedicalFacilities()` with real location
- ✅ Added error handling and loading state
- ✅ Added refresh functionality
- ✅ Shows real facility data: name, type, distance, rating, address, hours

---

## 2. Emergency Services Screen

### File
`tourist_app/lib/screens/emergency_services_screen.dart`

### Updated Implementation
```dart
class EmergencyServicesScreen extends StatefulWidget {
  @override
  State<EmergencyServicesScreen> createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> policeServices = [];
  List<Map<String, dynamic>> ambulanceServices = [];
  List<Map<String, dynamic>> fireServices = [];
  bool isLoading = false;
  String? errorMessage;
  double? currentLat;
  double? currentLon;
  String _selectedService = 'police';

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchServices();
  }

  Future<void> _getCurrentLocationAndFetchServices() async {
    try {
      setState(() => isLoading = true);

      // Get user's current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );

      currentLat = position.latitude;
      currentLon = position.longitude;

      // Fetch emergency services for different types
      final policeResponse = await _apiService.getEmergencyServices(
        latitude: currentLat!,
        longitude: currentLon!,
        serviceType: 'police',
        radius: 5000,
      );

      final ambulanceResponse = await _apiService.getEmergencyServices(
        latitude: currentLat!,
        longitude: currentLon!,
        serviceType: 'ambulance',
        radius: 5000,
      );

      final fireResponse = await _apiService.getEmergencyServices(
        latitude: currentLat!,
        longitude: currentLon!,
        serviceType: 'fire',
        radius: 5000,
      );

      setState(() {
        policeServices = List<Map<String, dynamic>>.from(policeResponse['services'] ?? []);
        ambulanceServices = List<Map<String, dynamic>>.from(ambulanceResponse['services'] ?? []);
        fireServices = List<Map<String, dynamic>>.from(fireResponse['services'] ?? []);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load services: $e';
      });
      print('Error: $e');
    }
  }

  List<Map<String, dynamic>> _getSelectedServices() {
    switch (_selectedService) {
      case 'police':
        return policeServices;
      case 'ambulance':
        return ambulanceServices;
      case 'fire':
        return fireServices;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text('Error: $errorMessage'));
    }

    final selectedServices = _getSelectedServices();

    return Column(
      children: [
        // Service type selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _selectedService = 'police'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedService == 'police' ? Colors.blue : Colors.grey,
                ),
                child: const Text('🚓 Police'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _selectedService = 'ambulance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedService == 'ambulance' ? Colors.red : Colors.grey,
                ),
                child: const Text('🚑 Ambulance'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _selectedService = 'fire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedService == 'fire' ? Colors.orange : Colors.grey,
                ),
                child: const Text('🚒 Fire'),
              ),
            ],
          ),
        ),
        // Service list
        Expanded(
          child: selectedServices.isEmpty
              ? const Center(child: Text('No services found nearby'))
              : RefreshIndicator(
                  onRefresh: _getCurrentLocationAndFetchServices,
                  child: ListView.builder(
                    itemCount: selectedServices.length,
                    itemBuilder: (context, index) {
                      final service = selectedServices[index];
                      final distance = (service['distance'] as num?)?.toStringAsFixed(2) ?? 'N/A';
                      return ListTile(
                        leading: Icon(
                          _selectedService == 'police'
                              ? Icons.local_police
                              : _selectedService == 'ambulance'
                                  ? Icons.local_hospital
                                  : Icons.fire_truck,
                          color: Colors.red,
                        ),
                        title: Text(service['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Distance: $distance km'),
                            if (service['rating'] != null)
                              Text('Rating: ⭐ ${service['rating']}'),
                          ],
                        ),
                        onTap: () {
                          // Show service details
                          _showServiceDetails(service);
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showServiceDetails(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $_selectedService'),
            Text('Address: ${service['address'] ?? 'N/A'}'),
            Text('Distance: ${(service['distance'] as num).toStringAsFixed(2)} km'),
            if (service['rating'] != null)
              Text('Rating: ⭐ ${service['rating']}'),
            if (service['phone'] != null)
              Text('Phone: ${service['phone']}'),
            if (service['response_time'] != null)
              Text('Est. Response: ${service['response_time']} min'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Get Directions'),
            onPressed: () {
              final lat = service['lat'];
              final lon = service['lon'];
              final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}
```

### Key Changes:
- ✅ Removed hardcoded service lists
- ✅ Fetches real police, ambulance, fire locations from API
- ✅ Added service type selector (tabs)
- ✅ Shows real response times and ratings
- ✅ Dynamic refresh capability

---

## 3. Area Safety Screen

### File
`tourist_app/lib/screens/area_safety_screen.dart`

### Updated Implementation
```dart
class AreaSafetyScreen extends StatefulWidget {
  @override
  State<AreaSafetyScreen> createState() => _AreaSafetyScreenState();
}

class _AreaSafetyScreenState extends State<AreaSafetyScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? safetyData;
  bool isLoading = false;
  String? errorMessage;
  double? currentLat;
  double? currentLon;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchSafety();
  }

  Future<void> _getCurrentLocationAndFetchSafety() async {
    try {
      setState(() => isLoading = true);

      // Get user's current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );

      currentLat = position.latitude;
      currentLon = position.longitude;

      // Fetch real safety data from API
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
        errorMessage = 'Failed to load safety data: $e';
      });
      print('Error: $e');
    }
  }

  Color _getWarningColor(String? warningLevel) {
    switch (warningLevel) {
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
    switch (warningLevel) {
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text('Error: $errorMessage'));
    }

    if (safetyData == null) {
      return const Center(child: Text('No safety data available'));
    }

    final safetyScore = safetyData!['safety_score'] ?? 0;
    final warningLevel = safetyData!['warning_level'] ?? 'UNKNOWN';
    final crimeRate = safetyData!['crime_rate'] ?? 0;
    final recentIncidents = safetyData!['recent_incidents'] ?? 0;
    final sources = safetyData!['sources'] ?? [];
    final lastUpdated = safetyData!['last_updated'] ?? 'Unknown';

    return RefreshIndicator(
      onRefresh: _getCurrentLocationAndFetchSafety,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Safety Score Card
          Card(
            color: _getWarningColor(warningLevel),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '${_getWarningEmoji(warningLevel)} Area Safety',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Safety Score: $safetyScore/100',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: $warningLevel',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Crime Rate
          ListTile(
            leading: const Icon(Icons.crime),
            title: const Text('Crime Rate'),
            subtitle: Text('$crimeRate incidents per 1000 people'),
          ),
          // Recent Incidents
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Recent Incidents'),
            subtitle: Text('$recentIncidents reported in this area'),
          ),
          // Data Sources
          ListTile(
            leading: const Icon(Icons.source),
            title: const Text('Data Sources'),
            subtitle: Text(sources.join(', ')),
          ),
          // Last Updated
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Last Updated'),
            subtitle: Text(lastUpdated),
          ),
          const SizedBox(height: 16),
          // Safety Tips
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safety Tips',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    warningLevel == 'HIGH'
                        ? '⚠️ Consider using official transportation and avoid traveling alone'
                        : warningLevel == 'MEDIUM'
                            ? '⚡ Stay alert, avoid unfamiliar areas after dark'
                            : '✅ Area appears relatively safe. Normal precautions apply',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Key Changes:
- ✅ Removed hardcoded safety ratings
- ✅ Calls `_apiService.getAreaSafety()` with real location
- ✅ Display real-time safety score (0-100)
- ✅ Shows warning level: HIGH/MEDIUM/LOW with color coding
- ✅ Displays actual crime rates and recent incidents
- ✅ Shows data sources (official + user reports)
- ✅ Timestamp of last update
- ✅ Dynamic safety tips based on actual warning level

---

## Testing Checklist

Before considering updates complete:

```
Frontend Changes:
☐ Medical Facilities Screen: Loads real hospitals
☐ Emergency Services Screen: Shows real police/fire/ambulance
☐ Area Safety Screen: Displays real safety score
☐ All screens handle loading states
☐ All screens handle error states
☐ Pull-to-refresh works on all screens

Data Verification:
☐ Hospitals show real addresses and ratings from Google
☐ Emergency services show correct response times
☐ Safety scores match backend calculations
☐ Distance calculations are accurate
☐ Last updated timestamp is current

Performance:
☐ Screens load in < 5 seconds
☐ No hardcoded data visible
☐ Real data from backend API
☐ Error messages show helpful info

Safety:
☐ Only verified data sources displayed
☐ Source attribution visible
☐ Data freshness indicated
```

---

## Common Issues & Solutions

### Issue 1: API returns 400 (Bad Request)
```
Problem: Location parameters not in correct format
Solution: Ensure latitude/longitude are doubles, not strings:
  ✅ CORRECT: latitude: 28.7041 (double)
  ❌ WRONG: latitude: "28.7041" (string)
```

### Issue 2: API returns 401 (Unauthorized)
```
Problem: Token is expired or not sent
Solution: Check token is saved and not expired:
  - Login to refresh token
  - Check SharedPreferences has valid token
```

### Issue 3: API returns 500 (Server Error)
```
Problem: Backend API not responding or Google API key not set
Solution: Check backend:
  1. Verify GOOGLE_MAPS_API_KEY is in Django settings.py
  2. Verify external_apis.py is imported correctly
  3. Restart Django server
```

### Issue 4: Map launches with wrong coordinates
```
Problem: Latitude/longitude not correctly passed to Google Maps
Solution: Verify the API response includes lat/lon fields:
  'lat': 28.7041,
  'lon': 77.1025,
```

---

## Summary

| Screen | Status | Changes |
|--------|--------|---------|
| Medical Facilities | ⏳ Update pending | Remove hardcoded, call API |
| Emergency Services | ⏳ Update pending | Remove hardcoded, call API |
| Area Safety | ⏳ Update pending | Remove hardcoded, call API |
| Emergency Contacts | ✅ Already updated | Fetches from API |
| Other Screens | ✅ Using real data | No changes needed |

**Expected Result After Updates**:
- 🏥 Real hospitals with actual ratings and hours
- 🚓 Real police/fire/ambulance locations and response times
- ⚠️ Real safety scores based on official crime data + user reports
- 📍 All data sourced from verified external APIs
- ✅ No more hardcoded or demo data

