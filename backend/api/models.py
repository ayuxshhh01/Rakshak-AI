from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    phone_number = models.CharField(max_length=15, blank=True)
    emergency_contact = models.CharField(max_length=15, blank=True)
    safety_score = models.IntegerField(default=90)
    blockchain_id = models.CharField(max_length=100, blank=True)
    last_location_update = models.DateTimeField(null=True, blank=True)
    last_altitude = models.FloatField(null=True, blank=True)
    location_history = models.JSONField(default=list)

    def __str__(self):
        return self.username


class Alert(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    alert_type = models.CharField(max_length=50)
    location = models.JSONField()
    timestamp = models.DateTimeField(auto_now_add=True)
    heart_rate = models.IntegerField(null=True, blank=True)
    details = models.JSONField(null=True, blank=True)
    STATUS_CHOICES = [
        ('Unassigned', 'Unassigned'),
        ('Acknowledged', 'Acknowledged'),
        ('Assigned', 'Assigned'),
        ('Resolved', 'Resolved'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Unassigned')
    assigned_to = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_alerts')

    def __str__(self):
        return f"{self.alert_type} for {self.user.username} ({self.status})"

class GeoZone(models.Model):
    name = models.CharField(max_length=100)
    zone_type = models.CharField(max_length=50, default='High-Risk')
    center_lat = models.FloatField()
    center_lon = models.FloatField()
    radius_km = models.FloatField()

    def __str__(self):
        return self.name

class Itinerary(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    plan_data = models.JSONField()

    def __str__(self):
        return f"Itinerary for {self.user.username}"


# ============= NEW FEATURES FOR TOURIST SAFETY =============

# 1. TRUSTED CIRCLE - Family Location Sharing
class TrustedCircleMember(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='trusted_circle')
    name = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=15)
    relationship = models.CharField(max_length=50, default='Family')  # Family, Friend, Emergency Contact
    can_see_location = models.BooleanField(default=True)
    can_see_status = models.BooleanField(default=True)
    date_added = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'phone_number')

    def __str__(self):
        return f"{self.name} in {self.user.username}'s circle"


# 2. SAFE ROUTE - Navigation Safety
class SafeRoute(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    start_location = models.JSONField()  # {'lat': x, 'lon': y}
    end_location = models.JSONField()
    route_name = models.CharField(max_length=200)
    waypoints = models.JSONField(default=list)
    danger_zones = models.JSONField(default=list)  # zones to avoid
    safety_score = models.IntegerField(default=85)  # 0-100
    distance_km = models.FloatField()
    estimated_time_minutes = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_saved = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.route_name} for {self.user.username}"


# 3. CHECK-IN - Proof of Life
class CheckIn(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    location = models.JSONField()  # {'lat': x, 'lon': y}
    location_name = models.CharField(max_length=200)
    status = models.CharField(
        max_length=50,
        choices=[
            ('Safe', 'Safe'),
            ('Moderate Risk', 'Moderate Risk'),
            ('Need Help', 'Need Help'),
        ],
        default='Safe'
    )
    note = models.TextField(blank=True)
    photo_url = models.URLField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    visibility = models.CharField(
        max_length=20,
        choices=[('Public', 'Public'), ('Trusted Circle', 'Trusted Circle'), ('Private', 'Private')],
        default='Trusted Circle'
    )

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.user.username} check-in at {self.location_name}"


# 4. AREA SAFETY RATING - Crime Rate / Safety
class AreaSafetyRating(models.Model):
    location_name = models.CharField(max_length=200)  # City, area name
    latitude = models.FloatField()
    longitude = models.FloatField()
    overall_rating = models.DecimalField(max_digits=3, decimal_places=2, default=7.5)  # 0-10
    crime_rate = models.DecimalField(max_digits=3, decimal_places=2, default=5.0)  # 0-10 (higher = more crime)
    theft_incidents = models.IntegerField(default=0)
    violent_incidents = models.IntegerField(default=0)
    safe_hours = models.JSONField(default=dict)  # {'start': '06:00', 'end': '20:00'}
    safe_areas = models.TextField(blank=True)  # description
    risky_areas = models.TextField(blank=True)
    user_reports_count = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.location_name} (Rating: {self.overall_rating})"


# 5. EMERGENCY NUMBER DIRECTORY
class EmergencyNumber(models.Model):
    country = models.CharField(max_length=50)
    city = models.CharField(max_length=100, blank=True)
    service_type = models.CharField(
        max_length=50,
        choices=[
            ('Police', 'Police'),
            ('Ambulance', 'Ambulance'),
            ('Fire', 'Fire'),
            ('Embassy', 'Embassy'),
            ('Tourist Police', 'Tourist Police'),
            ('Hospital', 'Hospital'),
            ('Other', 'Other'),
        ]
    )
    service_name = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=20)
    alternate_number = models.CharField(max_length=20, blank=True)
    description = models.TextField(blank=True)
    is_verified = models.BooleanField(default=True)
    language = models.CharField(max_length=50, default='English')

    class Meta:
        ordering = ['country', 'city', 'service_type']

    def __str__(self):
        return f"{self.service_type} - {self.country}: {self.phone_number}"


# 6. EMERGENCY PHRASES - Offline Language Support
class EmergencyPhrase(models.Model):
    language = models.CharField(max_length=50)  # English, Hindi, Spanish, etc.
    phrase_type = models.CharField(
        max_length=50,
        choices=[
            ('Help', 'Help'),
            ('Police', 'Police'),
            ('Hospital', 'Hospital'),
            ('Danger', 'Danger'),
            ('Safe', 'Safe'),
            ('Address', 'Address'),
            ('Water', 'Water'),
            ('Food', 'Food'),
            ('Bathroom', 'Bathroom'),
            ('Thank You', 'Thank You'),
            ('Yes/No', 'Yes/No'),
        ]
    )
    english_text = models.CharField(max_length=255)
    local_text = models.CharField(max_length=255)
    pronunciation = models.CharField(max_length=255, blank=True)
    audio_url = models.URLField(blank=True)

    class Meta:
        ordering = ['language', 'phrase_type']
        unique_together = ('language', 'phrase_type')

    def __str__(self):
        return f"{self.language} - {self.phrase_type}"


# 7. INCIDENT REPORT - Community Crowdsourced Safety
class IncidentReport(models.Model):
    reported_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='incident_reports')
    incident_type = models.CharField(
        max_length=100,
        choices=[
            ('Theft', 'Theft'),
            ('Assault', 'Assault'),
            ('Scam', 'Scam'),
            ('Harassment', 'Harassment'),
            ('Bad Transportation', 'Bad Transportation'),
            ('Dangerous Area', 'Dangerous Area'),
            ('Accident', 'Accident'),
            ('Other', 'Other'),
        ]
    )
    location = models.JSONField()  # {'lat': x, 'lon': y}
    location_name = models.CharField(max_length=200)
    description = models.TextField()
    severity = models.CharField(
        max_length=20,
        choices=[('Low', 'Low'), ('Medium', 'Medium'), ('High', 'High')],
        default='Medium'
    )
    timestamp = models.DateTimeField(auto_now_add=True)
    photo_url = models.URLField(blank=True)
    is_verified = models.BooleanField(default=False)
    helpful_count = models.IntegerField(default=0)  # like/upvote counter
    status = models.CharField(
        max_length=50,
        choices=[
            ('Pending Review', 'Pending Review'),
            ('Verified', 'Verified'),
            ('Under Investigation', 'Under Investigation'),
            ('Resolved', 'Resolved'),
        ],
        default='Pending Review'
    )

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.incident_type} reported by {self.reported_by.username}"

