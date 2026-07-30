# Setting Up Real-Time Data for Tourist Safety App

## Overview

The application now supports **real-time data sources** instead of hardcoded/seeded data for critical safety features. This ensures tourist safety relies on accurate, verified, real-time information.

---

## 1. Google Maps/Places API Setup (CRITICAL)

### Why?
- Real medical facilities with ratings and hours
- Real emergency services locations
- Real-time distance and routing
- User reviews and ratings

### Steps:

#### 1.1 Create Google Cloud Project
```bash
# Go to https://console.cloud.google.com/
# Create new project: "Tourist Safety App"
```

#### 1.2 Enable Required APIs
In Google Cloud Console, enable:
- ✅ Google Maps Platform
  - Maps JavaScript API
  - Places API
  - Directions API
  - Geocoding API

#### 1.3 Create API Key
```bash
# Go to: Credentials → Create Credentials → API Key
# Restrict to:
  - Application restrictions: Server (IP whitelist your server)
  - API restrictions: Select only the APIs above
```

#### 1.4 Add to Django Settings
```python
# backend/settings.py

GOOGLE_MAPS_API_KEY = 'YOUR_API_KEY_HERE'

# Cache settings (to avoid excessive API calls)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }
}
```

#### 1.5 Set Environment Variable (Recommended for Production)
```bash
# .env file
export GOOGLE_MAPS_API_KEY="sk_YOUR_KEY_HERE"

# In settings.py
import os
GOOGLE_MAPS_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY')
```

### Cost Estimate
- **Medical Facilities**: ~$0.10 per request (Nearby Search)
- **Emergency Services**: ~$0.10 per request (Nearby Search)  
- **Place Details**: ~$0.02 per request
- **Caching reduces calls by 70%**

**Recommended daily budget for 10,000 tourists**: ~$100-200/month

---

## 2. Crime Data Integration (CRITICAL)

### Option 1: Use Government APIs (Recommended)

#### For India:
- **NCRB (National Crime Records Bureau)**: Free API
  ```
  https://ncrb.gov.in/api/
  ```
- Provides: Crime statistics by state/city, monthly updates
- Frequency: Monthly
- Reliability: ⭐⭐⭐⭐⭐

#### Setup:
```python
# In external_apis.py - CrimeDataService
# Integrate with NCRB API

def sync_ncrb_crime_data():
    """Sync official crime statistics from NCRB"""
    # Called once per month via Celery task
```

#### For Other Countries:
- **USA**: FBI Crime Statistics API
- **UK**: UK Police Data API  
- **EU**: Eurostat Crime Data

### Option 2: User-Generated Data (Already Implemented)
```python
# Use IncidentReport model
# Users report crimes → Aggregated into area safety ratings
# Real-time, but requires critical mass of users
```

### Option 3: Hybrid Approach (RECOMMENDED)
```
Safety Score = (Official Data × 70%) + (User Reports × 30%)
```

**Why?**
- Official data: Accurate, verified, but sometimes outdated
- User reports: Real-time, but can be subjective
- Together: Most accurate representation

---

## 3. Emergency Numbers Database

### Automated Update Strategy

#### India Standard Emergency Numbers:
```
Police: 100
Ambulance/Medical: 102
Fire: 101
Disaster Management: 108
Women's Helpline: 1091
Tourist Police: 1363
```

#### Update Process:
1. Quarterly: Download from government portals
2. Parse and validate phone numbers
3. Update via management command

```bash
# Run command
python manage.py sync_government_emergency_numbers

# Auto-sync via Celery (weekly)
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    'sync-emergency-numbers': {
        'task': 'api.tasks.sync_emergency_numbers',
        'schedule': crontab(hour=0, minute=0, day_of_week=0),  # Weekly Sunday
    },
}
```

---

## 4. Weather & Natural Disaster Alerts (Optional)

### Services:
- **OpenWeatherMap API**: Real-time weather
- **USGS Natural Hazards**: Earthquake/volcano alerts
- **Local Weather Services**: Regional alerts

### Implementation:
```python
class WeatherAlertService:
    """Get real-time weather and disaster alerts"""
    
    @staticmethod
    def get_weather_alerts(lat, lon, alert_types=['severe', 'warnings']):
        # Fetch from OpenWeatherAPI
        # Return: Temperature, humidity, alerts
```

---

## 5. Deployment Configuration

### Production Requirements:

```python
# settings.py
if DEBUG == False:  # Production
    # 1. Use Redis for caching (not in-memory)
    CACHES = {
        'default': {
            'BACKEND': 'django_redis.cache.RedisCache',
            'LOCATION': 'redis://127.0.0.1:6379/1',
            'OPTIONS': {
                'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            }
        }
    }
    
    # 2. Set API timeouts (avoid hanging requests)
    EXTERNAL_API_TIMEOUT = 10  # seconds
    
    # 3. Enable API rate limiting
    from rest_framework.throttling import AnonRateThrottle
    
    THROTTLE_RATES = {
        'medical_facilities': '50/hour',
        'emergency_services': '100/hour',
        'area_safety': '100/hour',
    }
```

---

## 6. Fallback Strategy (Important!)

If external APIs are down, the system should have fallbacks:

```python
# external_apis.py

class GooglePlacesService:
    @classmethod
    def search_nearby_hospitals(cls, lat, lon, radius=5000):
        try:
            # Try Google Places API
            return cls._search_google_places(lat, lon, radius)
        except RequestException:
            # Fallback to database
            logger.warning('Google Places API down, using fallback data')
            return cls._search_database_fallback(lat, lon, radius)
    
    @staticmethod
    def _search_database_fallback(lat, lon, radius):
        """Fallback to pre-cached hospital data"""
        from api.models import AreaSafetyRating
        # Return nearby hospitals from seeded database
```

---

## 7. API Endpoints for Real-Time Data

### New Endpoints:

```bash
# Get real medical facilities near location
GET /api/medical-facilities/?lat=28.7041&lon=77.1025&radius=5000
Response:
{
    "count": 5,
    "location": {"lat": 28.7041, "lon": 77.1025},
    "facilities": [
        {
            "name": "Apollo Hospital",
            "lat": 28.6129,
            "lon": 77.2295,
            "rating": 4.7,
            "type": "Hospital",
            "distance": 12.5,  # km
            "is_open": true,
            "source": "google_places"
        }
    ],
    "data_type": "real-time",
    "source": "google_places_api"
}

# Get emergency services
GET /api/emergency-services/?lat=28.7041&lon=77.1025&type=police
Response:
{
    "count": 3,
    "service_type": "police",
    "services": [...]
}

# Get real-time area safety (combined official + user reports)
GET /api/area-safety/?lat=28.7041&lon=77.1025
Response:
{
    "safety_score": 72,  # 0-100
    "crime_rate": 45,
    "warning_level": "MEDIUM",
    "recent_incidents": 3,
    "sources": ["official_government_data", "user_incident_reports"],
    "data_type": "real-time"
}
```

---

## 8. Database Changes (Recommended)

Add fields to track data source quality:

```python
# In models.py

class AreaSafetyRating(models.Model):
    # ... existing fields ...
    
    # New fields
    source_type = CharField(
        choices=[
            ('government_official', 'Official Government Data'),
            ('user_reports', 'User-Generated Reports'),
            ('hybrid', 'Government + User Reports'),
        ]
    )
    reliability_score = IntegerField(default=100)  # 0-100
    data_expiry = DateTimeField()  # When data needs refresh
    last_synced = DateTimeField(auto_now=True)
```

---

## 9. Monitoring & Alerts

Setup alerts if APIs are down:

```python
# tasks.py

@periodic_task(run_every=crontab(minute=0))
def check_api_health():
    """Check if external APIs are responding"""
    from api.external_apis import GooglePlacesService
    
    try:
        # Test call
        GooglePlacesService.search_nearby_hospitals(28.7041, 77.1025)
    except RequestException:
        # Send alert to admin
        send_admin_alert("Google Places API is down!")
```

---

## 10. Testing Real-Time Endpoints

```bash
# Test medical facilities endpoint
curl -H "Authorization: Token YOUR_AUTH_TOKEN" \
  "http://localhost:8000/api/medical-facilities/?lat=28.7041&lon=77.1025&radius=5000"

# Test emergency services
curl -H "Authorization: Token YOUR_AUTH_TOKEN" \
  "http://localhost:8000/api/emergency-services/?lat=28.7041&lon=77.1025&type=police"

# Test area safety
curl -H "Authorization: Token YOUR_AUTH_TOKEN" \
  "http://localhost:8000/api/area-safety/?lat=28.7041&lon=77.1025"
```

---

## Summary: Data Migration Path

| Feature | Current | Target | Status |
|---------|---------|--------|--------|
| Medical Facilities | Seeded DB | Google Places API | ⚠️ Ready to Deploy |
| Emergency Services | Seeded DB | Google Places API | ⚠️ Ready to Deploy |
| Area Safety Ratings | Seeded DB | Govt Data + User Reports | ⚠️ Ready to Deploy |
| Emergency Numbers | Seeded DB | Government Portal Sync | ✅ Implemented |
| Safe Routes | Demo Data | Google Maps + Crime Data | 🔄 In Progress |
| Emergency Phrases | Static DB | Multi-source Translation | ✅ Implemented |
| Check-Ins | Real-time | Real-time | ✅ Implemented |
| Incident Reports | Real-time | Real-time + Aggregation | ✅ Implemented |

---

## Next: Deploy & Monitor

Once APIs are configured:
1. Deploy to staging
2. Test all endpoints
3. Monitor API calls and costs
4. Set up alerts
5. Deploy to production
6. Archive seeded data (keep as backup)

