from rest_framework import serializers
from .models import (
    CustomUser, Alert, GeoZone, Itinerary,
    TrustedCircleMember, SafeRoute, CheckIn, AreaSafetyRating,
    EmergencyNumber, EmergencyPhrase, IncidentReport
)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'password', 'phone_number', 'emergency_contact', 'safety_score', 'blockchain_id']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = CustomUser.objects.create_user(**validated_data)
        return user

# --- UPDATED: Add altitude to the LocationSerializer ---
class LocationSerializer(serializers.Serializer):
    lat = serializers.FloatField()
    lon = serializers.FloatField()
    altitude = serializers.FloatField(required=False, default=None) # Make it optional so older apps don't break

class ItinerarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Itinerary
        fields = ['id', 'user', 'plan_data']

class GeoZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = GeoZone
        fields = ['id', 'name', 'zone_type', 'center_lat', 'center_lon', 'radius_km']

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()


# ============= NEW SERIALIZERS FOR TOURIST SAFETY FEATURES =============

# 1. TRUSTED CIRCLE
class TrustedCircleMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrustedCircleMember
        fields = ['id', 'name', 'phone_number', 'relationship', 'can_see_location', 'can_see_status', 'date_added']
        read_only_fields = ['id', 'date_added', 'user']


# 2. SAFE ROUTE
class SafeRouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = SafeRoute
        fields = ['id', 'user', 'start_location', 'end_location', 'route_name', 'waypoints', 'danger_zones', 'safety_score', 'distance_km', 'estimated_time_minutes', 'is_saved', 'created_at']
        read_only_fields = ['id', 'created_at', 'user']


# 3. CHECK-IN
class CheckInSerializer(serializers.ModelSerializer):
    class Meta:
        model = CheckIn
        fields = ['id', 'user', 'location', 'location_name', 'status', 'note', 'photo_url', 'timestamp', 'visibility']
        read_only_fields = ['id', 'timestamp', 'user']


# 4. AREA SAFETY RATING
class AreaSafetyRatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = AreaSafetyRating
        fields = ['id', 'location_name', 'latitude', 'longitude', 'overall_rating', 'crime_rate', 'theft_incidents', 'violent_incidents', 'safe_hours', 'safe_areas', 'risky_areas', 'user_reports_count', 'last_updated']
        read_only_fields = ['id', 'last_updated']


# 5. EMERGENCY NUMBER
class EmergencyNumberSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyNumber
        fields = ['id', 'country', 'city', 'service_type', 'service_name', 'phone_number', 'alternate_number', 'description', 'is_verified', 'language']
        read_only_fields = ['id']


# 6. EMERGENCY PHRASE
class EmergencyPhraseSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyPhrase
        fields = ['id', 'language', 'phrase_type', 'english_text', 'local_text', 'pronunciation', 'audio_url']
        read_only_fields = ['id']


# 7. INCIDENT REPORT
class IncidentReportSerializer(serializers.ModelSerializer):
    reported_by_name = serializers.CharField(source='reported_by.username', read_only=True)

    class Meta:
        model = IncidentReport
        fields = ['id', 'reported_by', 'reported_by_name', 'incident_type', 'location', 'location_name', 'description', 'severity', 'timestamp', 'photo_url', 'is_verified', 'helpful_count', 'status']
        read_only_fields = ['id', 'timestamp', 'reported_by']

