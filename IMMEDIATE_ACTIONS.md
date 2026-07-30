# Immediate Actions: Activate Real-Time Data

**Goal**: Move from hardcoded data to real-time verified data for tourist safety.

**Status**: Infrastructure complete ✅ | API credentials pending ⏳

---

## BLOCKERS (Must Complete First)

### ❌ BLOCKER 1: Google Maps API Key
**What**: Set up Google Cloud project and get API key
**Time**: 20 minutes
**Steps**:
1. Go to https://console.cloud.google.com/
2. Create new project: "Tourist Safety"
3. Enable APIs:
   - Places API
   - Maps JavaScript API
   - Directions API
4. Create API key (Credentials → API Key)
5. Restrict to IP address of your server
6. Copy key

**Next Step**: Add to Django settings

---

### 🔧 BLOCKER 2: Configure Django Settings
**What**: Add API key to settings.py
**Time**: 5 minutes
**File**: `backend/settings.py`
**Add**:
```python
# Real-time data sources
GOOGLE_MAPS_API_KEY = 'your_api_key_here'

# Or use environment variable (recommended)
import os
GOOGLE_MAPS_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY', '')
```

**Next Step**: Test API calls in backend

---

## PHASE 1: Backend Testing (30 min)

### ✅ Test Google Places Integration

```bash
# SSH into backend
cd backend

# Test if external_apis module loads
python manage.py shell
>>> from api.external_apis import GooglePlacesService
>>> result = GooglePlacesService.search_nearby_hospitals(28.7041, 77.1025)
>>> print(result)
# Should return list of hospital objects
```

### ✅ Test API Endpoints

```bash
# Run server
python manage.py runserver

# Test medical facilities endpoint
curl -H "Authorization: Token YOUR_TOKEN" \
  "http://localhost:8000/api/medical-facilities/?lat=28.7041&lon=77.1025&radius=5000"

# Should return JSON with real hospitals
```

---

## PHASE 2: Flutter Updates (45 min)

### Update Medical Facilities Screen
**File**: `tourist_app/lib/screens/medical_facilities_screen.dart`
**Change**: Remove hardcoded hospitals, call API

```dart
// OLD: Hardcoded
List<Map<String, dynamic>> facilities = [
    {'name': 'Apollo Hospital', 'distance': 1.2, ...},
    ...
];

// NEW: Real API
Future<void> fetchMedicalFacilities() async {
    final response = await apiService.getMedicalFacilities(
        latitude: currentLat,
        longitude: currentLon,
        radius: 5000
    );
    setState(() {
        facilities = response.facilities;
    });
}

@override
initState() {
    super.initState();
    fetchMedicalFacilities();  // Call on init
}
```

**Details**:
- Get user's current location from Geolocator
- Call `/api/medical-facilities/` with lat, lon, radius
- Display real hospitals with ratings and distances
- Handle loading and error states

---

### Update Emergency Services Screen
**File**: `tourist_app/lib/screens/emergency_services_screen.dart`
**Change**: Call real emergency services API

```dart
// Fetch real emergency services
Future<void> fetchEmergencyServices() async {
    final response = await apiService.getEmergencyServices(
        latitude: currentLat,
        longitude: currentLon,
        serviceType: 'police'  // or 'ambulance', 'fire'
    );
    setState(() {
        services = response.services;
    });
}
```

---

### Update Area Safety Screen
**File**: `tourist_app/lib/screens/area_safety_screen.dart`
**Change**: Get real safety scores from backend

```dart
// Fetch real safety data
Future<void> fetchAreaSafety() async {
    final response = await apiService.getAreaSafety(
        latitude: currentLat,
        longitude: currentLon,
        city: currentCity
    );
    setState(() {
        safetyScore = response.safetyScore;  // 0-100
        warningLevel = response.warningLevel;  // HIGH/MEDIUM/LOW
    });
}
```

---

## PHASE 3: Testing End-to-End (30 min)

### Test on Device/Emulator

```bash
# In tourist_app/
flutter run

# Go to Map & SOS section
# Check:
✅ Medical facilities load with real hospitals
✅ Displays distances correctly
✅ Tap hospital → Details with ratings and hours
✅ Emergency services show real nearby stations
✅ Area safety shows warning level and incidents
✅ All data is real, not hardcoded
```

### Performance Checklist
```
⏱️ Medical facilities load in < 3 seconds
⏱️ Emergency services load in < 3 seconds
⏱️ No more hardcoded data shown
⏱️ Error messages appear if API is down
⏱️ Data updates when user moves location
```

---

## PHASE 4: Deployment (Tomorrow)

Once Phase 1-3 are complete:

```bash
# 1. Deploy backend with real-time endpoints
cd backend
git add .
git commit -m "Add real-time data integration: Google Places, crime data"
git push

# 2. Deploy Flutter app
cd ../tourist_app
flutter build apk OR flutter build ios
# Upload to Play Store / App Store

# 3. Monitor
# Check Admin dashboard for API costs
# Monitor error rates
# Track API response times
```

---

## File Changes Summary

### Backend (Already Done ✅)
- ✅ `api/external_apis.py`: Created Google Places integration
- ✅ `api/views.py`: Updated views to use real APIs
- ✅ `api/urls.py`: Added new endpoints
- ⏳ `settings.py`: Add API key (PENDING)

### Frontend (TODO 🔄)
- ⏳ `medical_facilities_screen.dart`: Remove hardcoded data, add API call
- ⏳ `emergency_services_screen.dart`: Add API integration
- ⏳ `area_safety_screen.dart`: Add real safety score call
- ⏳ `api/api_service.dart`: Add methods for new endpoints

### Testing (TODO 🔄)
- ⏳ Test all endpoints with real location data
- ⏳ Verify data accuracy against manual inspection
- ⏳ Check performance and API costs

---

## Verification Checklist

Before considering "complete":

```
Data Source Verification:
☐ Medical facilities from Google Places (verified)
☐ Emergency services from Google Maps (verified)
☐ Area safety scores from government+user data (verified)
☐ Emergency numbers from government sources (verified)

Functionality:
☐ All screens load without errors
☐ No more "hardcoded" or "demo" data visible
☐ Real hospitals/services shown on map
☐ Performance acceptable (<5s load time)
☐ Error handling works when APIs are down

Safety:
☐ Only verified data sources used
☐ Source attribution shown to user
☐ Data freshness indicated
☐ Fallback data works if API fails
```

---

## Quick Reference Commands

```bash
# Check if API key is set
grep GOOGLE_MAPS_API_KEY backend/settings.py

# Test backend API manually
python manage.py shell
from api.external_apis import GooglePlacesService
GooglePlacesService.search_nearby_hospitals(28.7041, 77.1025)

# Run Flutter with debug output
flutter run -v

# Check API response in Flutter
# Look for network calls in Network tab of DevTools
```

---

## Timeline

| Phase | Task | Time | Start | Complete |
|-------|------|------|-------|----------|
| 0 | Get API key | 20 min | NOW | TODAY |
| 0 | Configure Django | 5 min | TODAY | TODAY |
| 1 | Test backend APIs | 30 min | TODAY | TODAY |
| 2 | Update Flutter | 45 min | TODAY | TODAY |
| 3 | End-to-end testing | 30 min | TODAY | TODAY |
| 4 | Deploy | Varies | TMRW | TMRW |

**Total Time to Real-Time Data**: ~2 hours

---

## What Changes for Users?

### Before (Current):
❌ "Apollo Hospital" - Same hardcoded hospital every time
❌ Emergency numbers not verified
❌ Safety ratings not based on real crime data

### After (After Real-Time):
✅ "Apollo Hospital" - Only if actually within radius
✅ Different hospitals based on actual location
✅ Real ratings from Google reviews
✅ Government-verified emergency numbers
✅ Safety based on actual crime statistics + recent incidents
✅ Live data from user incident reports

**This is why we cannot use hardcoded data for tourist safety!**

