import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_model.dart';

const String API_BASE_URL = "https://ecce-106-213-84-92.ngrok-free.app/api";

class ApiService {
  final http.Client _client = http.Client();
  String? _inMemoryToken;

  Future<String?> _getToken() async {
    if (_inMemoryToken != null) return _inMemoryToken;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token != null) {
      _inMemoryToken = token;
    }
    print('📱 Token: ${token != null ? '✅ Found' : '❌ Not found'}');
    return token;
  }
  
  void _logRequest(String method, String endpoint, {String? body}) {
    print('🚀 $method $endpoint');
    if (body != null) print('   Body: $body');
  }
  
  void _logResponse(int statusCode, String endpoint) {
    print('✅ Response: $statusCode for $endpoint');
  }
  
  void _logError(String endpoint, dynamic error) {
    print('❌ ERROR at $endpoint: $error');
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      _logRequest('POST', '$API_BASE_URL/login/', body: '{"username": "$username"}');
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Login request timeout after 15 seconds - server may be unreachable');
        },
      );
      
      _logResponse(response.statusCode, 'login/');
      print('🔑 Login Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userJson = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);

        if (userJson != null) {
          await prefs.setString('userData', jsonEncode(userJson));
        }

        _inMemoryToken = token;
        print('✅ Login successful, token saved');
        return {'success': true, 'user': UserModel.fromJson(userJson)};
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': '❌ Invalid credentials'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': '❌ Login endpoint not found - backend API issue'};
      } else {
        return {'success': false, 'message': '❌ Login error ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      _logError('login', e);
      return {'success': false, 'message': '❌ Network error: $e'};
    }
  }

  Future<UserModel?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      return UserModel.fromJson(jsonDecode(userDataString));
    }
    return null;
  }

  Future<bool> sendSosAlert(double lat, double lon) async {
    try {
      print('🚨 SOS Alert initiated at ($lat, $lon)');

      final connectivityResultList = await Connectivity().checkConnectivity();

      if (connectivityResultList.contains(ConnectivityResult.none)) {
        print("⚠️ No internet connection. Triggering offline voice call to emergency contact...");
        final prefs = await SharedPreferences.getInstance();
        final emergencyContact = prefs.getString('emergencyContact');

        if (emergencyContact == null || emergencyContact.isEmpty) {
          print("❌ Offline SOS failed: No emergency contact saved on the device.");
          return false;
        }

        try {
          final Uri launchUri = Uri(
            scheme: 'tel',
            path: emergencyContact,
          );
          if (await canLaunchUrl(launchUri)) {
            print('✅ Calling emergency contact: $emergencyContact');
            await launchUrl(launchUri);
            return true;
          }
          return false;
        } catch(e) {
          print("❌ Could not launch phone call: $e");
          return false;
        }
      } else {
        final token = await _getToken();
        if (token == null) {
          print("❌ SOS failed: No authentication token");
          return false;
        }
        
        _logRequest('POST', '$API_BASE_URL/alerts/panic/', body: '{"lat": $lat, "lon": $lon}');
        
        try {
          final response = await _client.post(
            Uri.parse('$API_BASE_URL/alerts/panic/'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
            body: jsonEncode({'lat': lat, 'lon': lon}),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('SOS request timeout after 15 seconds');
            },
          );
          
          print('📡 SOS Response Status: ${response.statusCode}');
          print('📡 SOS Response Body: ${response.body}');
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            print('✅ SOS Alert sent successfully');
            return true;
          } else {
            print('❌ SOS failed with status ${response.statusCode}: ${response.body}');
            return false;
          }
        } catch (e) {
          print('❌ Failed to send SOS alert via API: $e');
          return false;
        }
      }
    } catch (e) {
      print('❌ Unexpected error in sendSosAlert: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userData');
    _inMemoryToken = null;
  }

  Future<void> updateLocation(double lat, double lon, double altitude) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      await _client.post(
        Uri.parse('$API_BASE_URL/location/update/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode({'lat': lat, 'lon': lon, 'altitude': altitude}),
      );
    } catch (e) {
      print('Failed to update location: $e');
    }
  }

  Future<Map<String, dynamic>> register(String username, String password, String phone, String emergencyContact) async {
    try {
      final response = await _client.post(Uri.parse('$API_BASE_URL/register/'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': username, 'password': password, 'phone_number': phone, 'emergency_contact': emergencyContact}));
      if (response.statusCode == 201) return {'success': true};
      return {'success': false, 'message': 'Failed to register: ${response.body}'};
    } catch (e) {
      return {'success': false, 'message': 'A network error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('❌ No authentication token found');
      }
      
      _logRequest('GET', '$API_BASE_URL/dashboard/');
      
      final response = await _client.get(
        Uri.parse('$API_BASE_URL/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds');
        },
      );
      
      _logResponse(response.statusCode, 'dashboard/');
      print('📊 Dashboard Response: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('❌ Unauthorized: Token may be expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('❌ Dashboard endpoint not found on server: /dashboard/');
      } else {
        throw Exception('❌ API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _logError('getDashboardData', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateItinerary(String destination, int duration, String budget) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ No authentication token');
      
      _logRequest('POST', '$API_BASE_URL/itinerary/generate/');
      
      final response = await _client.post(
        Uri.parse('$API_BASE_URL/itinerary/generate/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode({'destination': destination, 'duration': duration, 'budget': budget}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );
      
      _logResponse(response.statusCode, 'itinerary/generate/');
      print('📋 Itinerary Response: ${response.body}');
      
      if (response.statusCode == 200) return jsonDecode(response.body);
      if (response.statusCode == 404) throw Exception('❌ Itinerary endpoint not found');
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('generateItinerary', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getGeoFences() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ No authentication token');
      
      _logRequest('GET', '$API_BASE_URL/geozones/');
      
      final response = await _client.get(
        Uri.parse('$API_BASE_URL/geozones/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );
      
      _logResponse(response.statusCode, 'geozones/');
      print('🗺️ Geozones Response: ${response.body}');
      
      if (response.statusCode == 200) return jsonDecode(response.body);
      if (response.statusCode == 404) throw Exception('❌ Geozones endpoint not found');
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('getGeoFences', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> handleAlertAction(int alertId, String action) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.post(
      Uri.parse('$API_BASE_URL/alerts/$alertId/action/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      body: jsonEncode({'action': action}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to handle alert action');
  }

  Future<Map<String, dynamic>> getTouristJourney(int userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.get(
      Uri.parse('$API_BASE_URL/tourists/$userId/journey/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load tourist journey');
  }

  Future<Map<String, dynamic>> getVoiceAlert(int alertId) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.get(
      Uri.parse('$API_BASE_URL/voice-alert/$alertId/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load voice alert');
  }

  // ============= NEW METHODS FOR 7 TOURIST SAFETY FEATURES =============

  // 1. TRUSTED CIRCLE METHODS
  Future<List<Map<String, dynamic>>> getTrustedCircle() async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.get(
      Uri.parse('$API_BASE_URL/trusted-circle/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load trusted circle');
  }

  Future<Map<String, dynamic>> addTrustedCircleMember(String name, String phoneNumber, String relationship) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ No authentication token');
      
      final body = jsonEncode({
        'name': name,
        'phone_number': phoneNumber,
        'relationship': relationship,
      });
      
      _logRequest('POST', '$API_BASE_URL/trusted-circle/', body: body);
      
      final response = await _client.post(
        Uri.parse('$API_BASE_URL/trusted-circle/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: body,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );
      
      _logResponse(response.statusCode, 'trusted-circle/');
      print('👥 Trusted Circle Response: ${response.body}');
      
      if (response.statusCode == 201) return jsonDecode(response.body);
      if (response.statusCode == 400) {
        throw Exception('❌ Validation Error: ${response.body}');
      }
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('addTrustedCircleMember', e);
      rethrow;
    }
  }

  Future<void> deleteTrustedCircleMember(int memberId) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.delete(
      Uri.parse('$API_BASE_URL/trusted-circle/$memberId/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode != 204) throw Exception('Failed to delete member');
  }

  Future<List<Map<String, dynamic>>> getSharedLocations() async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.get(
      Uri.parse('$API_BASE_URL/shared-locations/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load shared locations');
  }

  // 2. SAFE ROUTE METHODS
  Future<List<Map<String, dynamic>>> getSafeRoutes() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('User not authenticated');
      
      _logRequest('GET', '$API_BASE_URL/safe-routes/');
      
      final response = await _client.get(
        Uri.parse('$API_BASE_URL/safe-routes/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );
      
      _logResponse(response.statusCode, 'safe-routes/');
      print('🚴 Safe Routes Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🚴 Safe Routes Data: $data');
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map) {
          return [data.cast<String, dynamic>()];
        }
        return [];
      }
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('getSafeRoutes', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateSafeRoute(double startLat, double startLon, double endLat, double endLon, String routeName) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.post(
      Uri.parse('$API_BASE_URL/safe-routes/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      body: jsonEncode({
        'start_location': {'lat': startLat, 'lon': startLon},
        'end_location': {'lat': endLat, 'lon': endLon},
        'route_name': routeName,
        'waypoints': [],
        'danger_zones': [],
        'distance_km': 0.0,
        'estimated_time_minutes': 0,
      }),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to generate safe route');
  }

  // 3. CHECK-IN METHODS
  Future<List<Map<String, dynamic>>> getCheckIns() async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.get(
      Uri.parse('$API_BASE_URL/check-ins/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load check-ins');
  }

  Future<Map<String, dynamic>> createCheckIn(double lat, double lon, String locationName, String status, String note, String visibility) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ No authentication token');
      
      final body = jsonEncode({
        'lat': lat,
        'lon': lon,
        'location_name': locationName,
        'status': status,
        'note': note,
        'visibility': visibility,
      });
      
      _logRequest('POST', '$API_BASE_URL/check-ins/', body: body);
      
      final response = await _client.post(
        Uri.parse('$API_BASE_URL/check-ins/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: body,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );
      
      _logResponse(response.statusCode, 'check-ins/');
      print('📍 Check-In Response (Status ${response.statusCode}): ${response.body}');
      
      if (response.statusCode == 201) return jsonDecode(response.body);
      if (response.statusCode == 400) {
        final errorBody = response.body;
        print('📍 Check-In Validation Error Details: $errorBody');
        throw Exception('❌ Field validation error: $errorBody');
      }
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('createCheckIn', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPublicCheckIns() async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.get(
      Uri.parse('$API_BASE_URL/check-ins/public/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load public check-ins');
  }

  // 4. AREA SAFETY RATING METHODS
  Future<List<Map<String, dynamic>>> getAreaSafetyRatings({double? lat, double? lon, double? radius}) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    
    final uri = Uri.parse('$API_BASE_URL/area-safety/').replace(queryParameters: {
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
      if (radius != null) 'radius': radius.toString(),
    });

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load area safety ratings');
  }

  // 5. EMERGENCY NUMBER METHODS
  Future<List<Map<String, dynamic>>> getEmergencyNumbers({String? country, String? city, String? serviceType}) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    
    final uri = Uri.parse('$API_BASE_URL/emergency-numbers/').replace(queryParameters: {
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (serviceType != null) 'service_type': serviceType,
    });

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load emergency numbers');
  }

  // 6. EMERGENCY PHRASE METHODS
  Future<List<Map<String, dynamic>>> getEmergencyPhrases(String language) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    
    final uri = Uri.parse('$API_BASE_URL/emergency-phrases/').replace(
      queryParameters: {'language': language},
    );

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load emergency phrases');
  }

  // 7. INCIDENT REPORT METHODS
  Future<List<Map<String, dynamic>>> getIncidentReports() async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.get(
      Uri.parse('$API_BASE_URL/incident-reports/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load incident reports');
  }

  Future<Map<String, dynamic>> reportIncident(double lat, double lon, String locationName, String incidentType, String description, String severity) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.post(
      Uri.parse('$API_BASE_URL/incident-reports/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      body: jsonEncode({
        'incident_type': incidentType,
        'location': {'lat': lat, 'lon': lon},
        'location_name': locationName,
        'description': description,
        'severity': severity,
        'photo_url': '',
      }),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to report incident');
  }

  Future<void> likeIncidentReport(int reportId) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await _client.post(
      Uri.parse('$API_BASE_URL/incident-reports/$reportId/like/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to like report');
  }

  // ============= REAL-TIME DATA METHODS =============
  // Medical Facilities: Real hospital and clinic locations from Google Places
  Future<Map<String, dynamic>> getMedicalFacilities({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ No authentication token');

      final queryParams = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'radius': radius.toString(),
      };
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse('$API_BASE_URL/medical-facilities/').replace(
        queryParameters: queryParams,
      );

      _logRequest('GET', uri.toString());

      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Token $token'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout - server not responding'),
      );

      _logResponse(response.statusCode, 'medical-facilities/');
      print('🏥 Medical Facilities Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw Exception('❌ Invalid parameters: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('❌ Unauthorized: Please login again');
      } else if (response.statusCode == 500) {
        throw Exception('❌ Server error: Please try again later');
      }
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('getMedicalFacilities', e);
      rethrow;
    }
  }

  // Emergency Services: Real police, fire, ambulance locations from Google Places
  Future<Map<String, dynamic>> getEmergencyServices({
    required double latitude,
    required double longitude,
    String serviceType = 'police',
    int radius = 5000,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ No authentication token');

      final queryParams = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'service_type': serviceType,
        'radius': radius.toString(),
      };

      final uri = Uri.parse('$API_BASE_URL/emergency-services/').replace(
        queryParameters: queryParams,
      );

      _logRequest('GET', uri.toString());

      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Token $token'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout - server not responding'),
      );

      _logResponse(response.statusCode, 'emergency-services/');
      print('🚨 Emergency Services Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw Exception('❌ Invalid parameters: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('❌ Unauthorized: Please login again');
      } else if (response.statusCode == 500) {
        throw Exception('❌ Server error: Please try again later');
      }
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('getEmergencyServices', e);
      rethrow;
    }
  }

  // Area Safety: Real-time safety score based on official crime data + user reports
  Future<Map<String, dynamic>> getAreaSafety({
    required double latitude,
    required double longitude,
    String? city,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ No authentication token');

      final queryParams = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      };
      if (city != null) queryParams['city'] = city;

      final uri = Uri.parse('$API_BASE_URL/area-safety/').replace(
        queryParameters: queryParams,
      );

      _logRequest('GET', uri.toString());

      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Token $token'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout - server not responding'),
      );

      _logResponse(response.statusCode, 'area-safety/');
      print('📍 Area Safety Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw Exception('❌ Invalid parameters: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('❌ Unauthorized: Please login again');
      } else if (response.statusCode == 500) {
        throw Exception('❌ Server error: Please try again later');
      }
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('getAreaSafety', e);
      rethrow;
    }
  }

  /// Get safe routes based on user's itinerary
  Future<dynamic> getSafeRoutesFromItinerary() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ No authentication token');

      final uri = Uri.parse('$API_BASE_URL/safe-routes/');

      _logRequest('POST', uri.toString());

      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}), // Backend will get itinerary from authenticated user
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout - server not responding'),
      );

      _logResponse(response.statusCode, 'safe-routes/');
      print('🛣️ Safe Routes Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw Exception('❌ No itinerary found. Please create an itinerary first.');
      } else if (response.statusCode == 401) {
        throw Exception('❌ Unauthorized: Please login again');
      } else if (response.statusCode == 500) {
        throw Exception('❌ Server error: Please try again later');
      }
      throw Exception('❌ Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      _logError('getSafeRoutesFromItinerary', e);
      rethrow;
    }
  }
}
