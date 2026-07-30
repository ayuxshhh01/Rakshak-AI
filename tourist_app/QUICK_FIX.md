# 🚨 Quick Fix Checklist - API Issues

## Step 1: Check Your Backend (Django)
- [ ] Is Django running? (you should see `Running on http://127.0.0.1:8000`)
- [ ] If not, run: `python manage.py runserver`
- [ ] Check for any error messages in Django terminal

## Step 2: Check Your ngrok Tunnel
- [ ] Is ngrok running in a terminal?
- [ ] Does it show `Session Status: connected`?
- [ ] Note the forwarding URL (e.g., `https://xxxxx.ngrok-free.app`)
- [ ] If tunnel expired/restarted, you'll get a NEW URL

## Step 3: Update API_BASE_URL (if ngrok restarted)
Open [lib/api/api_service.dart](lib/api/api_service.dart) - Line 9:

```dart
const String API_BASE_URL = "https://YOUR-NEW-URL-HERE/api";
```

Replace with your current ngrok URL.

## Step 4: Run the App and Monitor Logs
- [ ] Start the app in VS Code
- [ ] Open: Debug Console (View → Debug Console)
- [ ] Look for any ❌ errors

## Step 5: Test Login First
- [ ] Try to login in the app
- [ ] Check logs for: `✅ Login successful`
- [ ] If fails, look for `❌ ERROR at login:`

## Step 6: Test Dashboard
- [ ] After successful login, go to dashboard
- [ ] Check logs for: `📊 Dashboard Response:`
- [ ] If error `404`, your Django doesn't have `/api/dashboard/` endpoint

## Step 7: Test SOS
- [ ] Click SOS button
- [ ] Check logs for: `🚨 SOS Alert initiated`
- [ ] If online (has internet), should see: `📡 SOS Response Status: 200`
- [ ] If error `404`, your Django doesn't have `/api/alerts/panic/` endpoint

---

## If Dashboard Shows "404 - Endpoint not found"

Your Django backend is missing the `/api/dashboard/` endpoint.

**You need to create this endpoint:**

```python
# In your Django urls.py
from django.urls import path, include

urlpatterns = [
    path('api/', include('your_app.urls')),  # Create this file
]

# In your_app/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('dashboard/', views.dashboard_view, name='dashboard'),
]

# In your_app/views.py
from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(['GET'])
def dashboard_view(request):
    return Response({
        'message': 'Dashboard data here',
        'user': request.user.username if request.user else 'anonymous',
    })
```

---

## If SOS Shows "404 - Endpoint not found"

Your Django backend is missing the `/api/alerts/panic/` endpoint.

**Add this to your Django:**

```python
# In your urls.py
urlpatterns = [
    path('api/alerts/panic/', views.send_sos_alert, name='send_sos'),
]

# In your views.py
@api_view(['POST'])
def send_sos_alert(request):
    lat = request.data.get('lat')
    lon = request.data.get('lon')
    
    # TODO: Send alert to trusted circle, police, etc.
    
    return Response({'status': 'SOS received', 'lat': lat, 'lon': lon})
```

---

## Common Issues & Quick Fixes

| Problem | Log Shows | Fix |
|---------|-----------|-----|
| Dashboard blank | `❌ No authentication token` | Login first |
| Dashboard blank | `Request timeout` | ngrok tunnel is dead, restart it |
| Dashboard blank | `endpoint not found` | Create `/api/dashboard/` in Django |
| SOS didn't work | `SOS failed: No token` | Login first |
| SOS didn't work | `SOS request timeout` | ngrok tunnel is down |
| SOS didn't work | `endpoint not found` | Create `/api/alerts/panic/` in Django |
| Any request fails | `Failed host lookup` | ngrok URL is old/wrong, update it |

---

## Your Backend Endpoints Checklist

Your Django needs these endpoints to work:

- [ ] `POST /api/login/` - Login user
- [ ] `GET /api/dashboard/` - Get dashboard data
- [ ] `POST /api/alerts/panic/` - Send SOS alert
- [ ] `GET /api/location/update/` - Update user location
- [ ] Other safety features...

---

## How to Know It's Working

✅ **Success signs:**
- Login works (see `✅ Login successful` in logs)
- Dashboard loads (see `📊 Dashboard Response:` with actual data)
- SOS sends instantly (see `✅ SOS Alert sent successfully`)
- No ❌ red errors in console

❌ **Failure signs:**
- `❌ ERROR` in logs
- Blank screens in app
- Long delays (timeouts)

---

## Need More Help?

1. **Read the full guide:** [API_DEBUG_GUIDE.md](API_DEBUG_GUIDE.md)
2. **Check Django logs** in the terminal running `runserver`
3. **Check ngrok logs** to see all requests
4. **Test with curl** to verify endpoint exists

Good luck! 🚀
