// ============= FLUTTER MODELS FOR 7 TOURIST SAFETY FEATURES =============

// 1. TRUSTED CIRCLE MODEL
class TrustedCircleMember {
  final int id;
  final int friendId;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool canSeeLocation;
  final bool canSeeStatus;
  final DateTime dateAdded;

  TrustedCircleMember({
    required this.id,
    required this.friendId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.canSeeLocation,
    required this.canSeeStatus,
    required this.dateAdded,
  });

  factory TrustedCircleMember.fromJson(Map<String, dynamic> json) {
    return TrustedCircleMember(
      id: json['id'] ?? 0,
      friendId: json['friend'] ?? 0,
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      relationship: json['relationship'] ?? 'Family',
      canSeeLocation: json['can_see_location'] ?? true,
      canSeeStatus: json['can_see_status'] ?? true,
      dateAdded: DateTime.parse(json['date_added'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friend': friendId,
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
      'can_see_location': canSeeLocation,
      'can_see_status': canSeeStatus,
    };
  }
}

// 2. SAFE ROUTE MODEL
class SafeRoute {
  final int id;
  final Map<String, double> startLocation;
  final Map<String, double> endLocation;
  final String routeName;
  final List<Map<String, double>> waypoints;
  final List<Map<String, dynamic>> dangerZones;
  final int safetyScore;
  final double distanceKm;
  final int estimatedTimeMinutes;
  final bool isSaved;
  final DateTime createdAt;

  SafeRoute({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.routeName,
    required this.waypoints,
    required this.dangerZones,
    required this.safetyScore,
    required this.distanceKm,
    required this.estimatedTimeMinutes,
    required this.isSaved,
    required this.createdAt,
  });

  factory SafeRoute.fromJson(Map<String, dynamic> json) {
    return SafeRoute(
      id: json['id'] ?? 0,
      startLocation: Map<String, double>.from(json['start_location'] ?? {}),
      endLocation: Map<String, double>.from(json['end_location'] ?? {}),
      routeName: json['route_name'] ?? '',
      waypoints: List<Map<String, double>>.from(json['waypoints'] ?? []),
      dangerZones: List<Map<String, dynamic>>.from(json['danger_zones'] ?? []),
      safetyScore: json['safety_score'] ?? 85,
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      estimatedTimeMinutes: json['estimated_time_minutes'] ?? 0,
      isSaved: json['is_saved'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_location': startLocation,
      'end_location': endLocation,
      'route_name': routeName,
      'waypoints': waypoints,
      'danger_zones': dangerZones,
      'distance_km': distanceKm,
      'estimated_time_minutes': estimatedTimeMinutes,
      'is_saved': isSaved,
    };
  }
}

// 3. CHECK-IN MODEL
class CheckIn {
  final int id;
  final Map<String, double> location;
  final String locationName;
  final String status;
  final String note;
  final String photoUrl;
  final DateTime timestamp;
  final String visibility;

  CheckIn({
    required this.id,
    required this.location,
    required this.locationName,
    required this.status,
    required this.note,
    required this.photoUrl,
    required this.timestamp,
    required this.visibility,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] ?? 0,
      location: Map<String, double>.from(json['location'] ?? {}),
      locationName: json['location_name'] ?? '',
      status: json['status'] ?? 'Safe',
      note: json['note'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      visibility: json['visibility'] ?? 'Trusted Circle',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'location_name': locationName,
      'status': status,
      'note': note,
      'photo_url': photoUrl,
      'visibility': visibility,
    };
  }
}

// 4. AREA SAFETY RATING MODEL
class AreaSafetyRating {
  final int id;
  final String locationName;
  final double latitude;
  final double longitude;
  final double overallRating;
  final double crimeRate;
  final int theftIncidents;
  final int violentIncidents;
  final Map<String, String> safeHours;
  final String safeAreas;
  final String riskyAreas;
  final int userReportsCount;
  final DateTime lastUpdated;

  AreaSafetyRating({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.overallRating,
    required this.crimeRate,
    required this.theftIncidents,
    required this.violentIncidents,
    required this.safeHours,
    required this.safeAreas,
    required this.riskyAreas,
    required this.userReportsCount,
    required this.lastUpdated,
  });

  factory AreaSafetyRating.fromJson(Map<String, dynamic> json) {
    return AreaSafetyRating(
      id: json['id'] ?? 0,
      locationName: json['location_name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      overallRating: (json['overall_rating'] ?? 7.5).toDouble(),
      crimeRate: (json['crime_rate'] ?? 5.0).toDouble(),
      theftIncidents: json['theft_incidents'] ?? 0,
      violentIncidents: json['violent_incidents'] ?? 0,
      safeHours: Map<String, String>.from(json['safe_hours'] ?? {}),
      safeAreas: json['safe_areas'] ?? '',
      riskyAreas: json['risky_areas'] ?? '',
      userReportsCount: json['user_reports_count'] ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'safe_hours': safeHours,
      'safe_areas': safeAreas,
      'risky_areas': riskyAreas,
    };
  }
}

// 5. EMERGENCY NUMBER MODEL
class EmergencyNumber {
  final int id;
  final String country;
  final String city;
  final String serviceType;
  final String serviceName;
  final String phoneNumber;
  final String alternateNumber;
  final String description;
  final bool isVerified;
  final String language;

  EmergencyNumber({
    required this.id,
    required this.country,
    required this.city,
    required this.serviceType,
    required this.serviceName,
    required this.phoneNumber,
    required this.alternateNumber,
    required this.description,
    required this.isVerified,
    required this.language,
  });

  factory EmergencyNumber.fromJson(Map<String, dynamic> json) {
    return EmergencyNumber(
      id: json['id'] ?? 0,
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      serviceType: json['service_type'] ?? '',
      serviceName: json['service_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      alternateNumber: json['alternate_number'] ?? '',
      description: json['description'] ?? '',
      isVerified: json['is_verified'] ?? true,
      language: json['language'] ?? 'English',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'city': city,
      'service_type': serviceType,
      'service_name': serviceName,
      'phone_number': phoneNumber,
      'alternate_number': alternateNumber,
      'description': description,
    };
  }
}

// 6. EMERGENCY PHRASE MODEL
class EmergencyPhrase {
  final int id;
  final String language;
  final String phraseType;
  final String englishText;
  final String localText;
  final String pronunciation;
  final String audioUrl;

  EmergencyPhrase({
    required this.id,
    required this.language,
    required this.phraseType,
    required this.englishText,
    required this.localText,
    required this.pronunciation,
    required this.audioUrl,
  });

  factory EmergencyPhrase.fromJson(Map<String, dynamic> json) {
    return EmergencyPhrase(
      id: json['id'] ?? 0,
      language: json['language'] ?? 'English',
      phraseType: json['phrase_type'] ?? '',
      englishText: json['english_text'] ?? '',
      localText: json['local_text'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      audioUrl: json['audio_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'phrase_type': phraseType,
    };
  }
}

// 7. INCIDENT REPORT MODEL
class IncidentReport {
  final int id;
  final int reportedById;
  final String reportedByName;
  final String incidentType;
  final Map<String, double> location;
  final String locationName;
  final String description;
  final String severity;
  final DateTime timestamp;
  final String photoUrl;
  final bool isVerified;
  final int helpfulCount;
  final String status;

  IncidentReport({
    required this.id,
    required this.reportedById,
    required this.reportedByName,
    required this.incidentType,
    required this.location,
    required this.locationName,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.photoUrl,
    required this.isVerified,
    required this.helpfulCount,
    required this.status,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      id: json['id'] ?? 0,
      reportedById: json['reported_by'] ?? 0,
      reportedByName: json['reported_by_name'] ?? '',
      incidentType: json['incident_type'] ?? '',
      location: Map<String, double>.from(json['location'] ?? {}),
      locationName: json['location_name'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'Medium',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      photoUrl: json['photo_url'] ?? '',
      isVerified: json['is_verified'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
      status: json['status'] ?? 'Pending Review',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incident_type': incidentType,
      'location': location,
      'location_name': locationName,
      'description': description,
      'severity': severity,
      'photo_url': photoUrl,
    };
  }
}

// SHARED LOCATION MODEL (for Trusted Circle)
class SharedLocation {
  final int userId;
  final String username;
  final Map<String, double> location;
  final DateTime timestamp;
  final int safetyScore;

  SharedLocation({
    required this.userId,
    required this.username,
    required this.location,
    required this.timestamp,
    required this.safetyScore,
  });

  factory SharedLocation.fromJson(Map<String, dynamic> json) {
    return SharedLocation(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      location: Map<String, double>.from(json['location'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      safetyScore: json['safety_score'] ?? 90,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'safety_score': safetyScore,
    };
  }
}
