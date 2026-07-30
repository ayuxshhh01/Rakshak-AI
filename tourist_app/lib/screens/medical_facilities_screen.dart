import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../bloc/location_bloc.dart';
import '../api/api_service.dart';

const Color primaryTeal = Color(0xFF006B5E);
const Color secondaryOrange = Color(0xFFE8753F);
const Color darkTextColor = Color(0xFF1A1F36);
const Color lightGreyText = Color(0xFF757575);
const Color cardColor = Colors.white;
const Color backgroundLight = Color(0xFFFAF9F6);

class MedicalFacilitiesScreen extends StatefulWidget {
  const MedicalFacilitiesScreen({Key? key}) : super(key: key);

  @override
  State<MedicalFacilitiesScreen> createState() => _MedicalFacilitiesScreenState();
}

class _MedicalFacilitiesScreenState extends State<MedicalFacilitiesScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final ApiService _apiService = ApiService();
  
  // Real-time data state
  List<Map<String, dynamic>> nearbyFacilities = [];
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
            errorMessage = '❌ Location permission is required to find nearby facilities';
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

      // Fetch real medical facilities from API
      final response = await _apiService.getMedicalFacilities(
        latitude: currentLat!,
        longitude: currentLon!,
        radius: 5000, // 5 km radius
      );

      setState(() {
        // Transform API response to match UI expectations
        nearbyFacilities = [];
        final facilities = response['facilities'] ?? [];
        
        for (var facility in facilities) {
          nearbyFacilities.add({
            'name': facility['name'] ?? 'Unknown Facility',
            'distance': '${((facility['distance'] ?? 0) / 1000).toStringAsFixed(2)} km',
            'rating': facility['rating'] ?? 0.0,
            'type': facility['type'] ?? 'Medical Facility',
            'icon': Icons.local_hospital_rounded,
            'color': _getColorForType(facility['type']),
            'address': facility['address'] ?? 'Address not available',
            'lat': facility['lat'],
            'lon': facility['lon'],
            'is_open': facility['is_open'] ?? false,
            'place_id': facility['place_id'],
            'source': 'google_places',
          });
        }

        isLoading = false;
        if (nearbyFacilities.isEmpty) {
          errorMessage = 'No medical facilities found nearby';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching facilities: $e';
      });
      print('🚨 Error: $e');
    }
  }

  Color _getColorForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'pharmacy':
        return Colors.green;
      case 'clinic':
        return Colors.blue;
      case 'ambulance':
        return Colors.purple;
      default:
        return Colors.orange;
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
            'Medical Facilities',
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
            'Medical Facilities',
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
                onPressed: _getCurrentLocationAndFetchFacilities,
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
        title: const Text(
          'Medical Facilities',
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

          // Facilities List with refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _getCurrentLocationAndFetchFacilities,
              color: primaryTeal,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: nearbyFacilities.length,
                itemBuilder: (context, index) {
                  final facility = nearbyFacilities[index];
                  return _buildFacilityCard(facility);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
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
                          color: facility['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(facility['icon'], color: facility['color'], size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facility['name'],
                              style: const TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 15),
                            ),
                            Text(
                              facility['type'],
                              style: const TextStyle(color: lightGreyText, fontSize: 12, fontWeight: FontWeight.w500),
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
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${facility['rating']}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      facility['distance'],
                      style: const TextStyle(color: lightGreyText, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              facility['address'],
              style: const TextStyle(color: lightGreyText, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final lat = facility['lat'];
                      final lon = facility['lon'];
                      final name = facility['name'];
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
                      backgroundColor: primaryTeal,
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
                      _showFacilityDetails(facility);
                    },
                    icon: const Icon(Icons.info_rounded, size: 18),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
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
            Text('Address: ${facility['address']}'),
            Text('Distance: ${facility['distance']}'),
            if ((facility['rating'] ?? 0) > 0)
              Text('Rating: ⭐ ${facility['rating']}'),
            if (facility['is_open'] != null)
              Text('Status: ${facility['is_open'] ? 'Open' : 'Closed'}'),
            const SizedBox(height: 12),
            Text(
              'Source: ${facility['source'] ?? 'Unknown'}',
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
              final lat = facility['lat'];
              final lon = facility['lon'];
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

