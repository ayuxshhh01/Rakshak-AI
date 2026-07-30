import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../api/api_service.dart';

const Color primaryTeal = Color(0xFF006B5E);
const Color secondaryOrange = Color(0xFFE8753F);
const Color darkTextColor = Color(0xFF1A1F36);
const Color lightGreyText = Color(0xFF757575);
const Color cardColor = Colors.white;
const Color backgroundLight = Color(0xFFFAF9F6);

class EmergencyServicesScreen extends StatefulWidget {
  const EmergencyServicesScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyServicesScreen> createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final ApiService _apiService = ApiService();

  // Real-time data state
  List<Map<String, dynamic>> policeServices = [];
  List<Map<String, dynamic>> ambulanceServices = [];
  List<Map<String, dynamic>> fireServices = [];

  bool isLoading = false;
  String? errorMessage;
  double? currentLat;
  double? currentLon;

  String _selectedServiceType = 'police';

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchServices();
  }

  Future<void> _getCurrentLocationAndFetchServices() async {
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
            errorMessage = '❌ Location permission is required to find nearby emergency services';
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

      // Fetch emergency services for all types in parallel
      final policeResponse = _apiService.getEmergencyServices(
        latitude: currentLat!,
        longitude: currentLon!,
        serviceType: 'police',
        radius: 5000,
      );

      final ambulanceResponse = _apiService.getEmergencyServices(
        latitude: currentLat!,
        longitude: currentLon!,
        serviceType: 'ambulance',
        radius: 5000,
      );

      final fireResponse = _apiService.getEmergencyServices(
        latitude: currentLat!,
        longitude: currentLon!,
        serviceType: 'fire',
        radius: 5000,
      );

      // Wait for all API calls
      final results = await Future.wait([policeResponse, ambulanceResponse, fireResponse]);

      setState(() {
        // Transform API responses to match UI expectations
        policeServices = _transformServices(results[0], 'police');
        ambulanceServices = _transformServices(results[1], 'ambulance');
        fireServices = _transformServices(results[2], 'fire');

        isLoading = false;

        // Check if no services found
        if (policeServices.isEmpty && ambulanceServices.isEmpty && fireServices.isEmpty) {
          errorMessage = 'No emergency services found nearby';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching services: $e';
      });
      print('🚨 Error: $e');
    }
  }

  List<Map<String, dynamic>> _transformServices(
    Map<String, dynamic> response,
    String serviceType,
  ) {
    final services = <Map<String, dynamic>>[];
    final servicesList = response['services'] ?? [];

    for (var service in servicesList) {
      services.add({
        'name': service['name'] ?? 'Unknown Service',
        'distance': '${((service['distance'] ?? 0) / 1000).toStringAsFixed(2)} km',
        'rating': service['rating'] ?? 0.0,
        'type': serviceType,
        'address': service['address'] ?? 'Address not available',
        'lat': service['lat'],
        'lon': service['lon'],
        'is_open': service['is_open'] ?? false,
        'place_id': service['place_id'],
        'source': 'google_places',
      });
    }

    return services;
  }

  List<Map<String, dynamic>> _getSelectedServices() {
    switch (_selectedServiceType) {
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

  Color _getColorForServiceType(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'police':
        return Colors.blue;
      case 'fire':
        return Colors.orange;
      case 'ambulance':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  IconData _getIconForServiceType(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'police':
        return Icons.local_police_rounded;
      case 'fire':
        return Icons.fire_truck_rounded;
      case 'ambulance':
        return Icons.emergency_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(
          title: const Text(
            'Emergency Services',
            style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
          ),
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
          title: const Text(
            'Emergency Services',
            style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
          ),
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
                style: const TextStyle(fontSize: 16, color: darkTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _getCurrentLocationAndFetchServices,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final selectedServices = _getSelectedServices();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Emergency Services',
          style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Map Preview with current location
          Container(
            height: 200,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(currentLat ?? 17.6599, currentLon ?? 75.9064),
                zoom: 14.0,
              ),
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) _mapController.complete(controller);
              },
              myLocationEnabled: true,
            ),
          ),

          // Service Type Selector (Tabs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildServiceTypeButton('Police', 'police', Colors.blue, Icons.local_police_rounded),
                _buildServiceTypeButton('Ambulance', 'ambulance', Colors.red, Icons.emergency_rounded),
                _buildServiceTypeButton('Fire', 'fire', Colors.orange, Icons.fire_truck_rounded),
              ],
            ),
          ),

          // Services List with refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _getCurrentLocationAndFetchServices,
              color: primaryTeal,
              child: selectedServices.isEmpty
                  ? Center(
                      child: Text(
                        'No ${_selectedServiceType} services found nearby',
                        style: const TextStyle(color: lightGreyText, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: selectedServices.length,
                      itemBuilder: (context, index) {
                        final service = selectedServices[index];
                        return _buildServiceCard(service);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeButton(
    String label,
    String serviceType,
    Color color,
    IconData icon,
  ) {
    final isSelected = _selectedServiceType == serviceType;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => _selectedServiceType = serviceType);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final color = _getColorForServiceType(service['type']);
    final icon = _getIconForServiceType(service['type']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: darkTextColor,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              service['type'].toUpperCase(),
                              style: const TextStyle(
                                color: lightGreyText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if ((service['rating'] ?? 0) > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${service['rating']}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 14),
                          ),
                        ],
                      ),
                    Text(
                      service['distance'],
                      style: const TextStyle(color: lightGreyText, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service['address'],
              style: const TextStyle(color: lightGreyText, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final lat = service['lat'];
                      final lon = service['lon'];
                      final name = service['name'];
                      final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving';

                      try {
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not open Google Maps for $name'),
                              backgroundColor: Colors.red.shade500,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error launching maps: $e'),
                            backgroundColor: Colors.red.shade500,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showServiceDetails(service);
                    },
                    icon: const Icon(Icons.info_rounded, size: 18),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showServiceDetails(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${service['type'].toUpperCase()}'),
            Text('Address: ${service['address']}'),
            Text('Distance: ${service['distance']}'),
            if ((service['rating'] ?? 0) > 0) Text('Rating: ⭐ ${service['rating']}'),
            if (service['is_open'] != null) Text('Status: ${service['is_open'] ? 'Open' : 'Closed'}'),
            const SizedBox(height: 12),
            Text(
              'Source: ${service['source'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () {
              Navigator.pop(context);
              final lat = service['lat'];
              final lon = service['lon'];
              final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: const Text('Get Directions', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
