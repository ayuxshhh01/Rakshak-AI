# API Debug Guide - Tourist Safety App

## 🚀 What Changed
The `api_service.dart` has been updated with **detailed logging and error messages**. Now when something fails, you'll see EXACTLY what the error is.

---

## 📱 How to Debug API Issues

### 1. **Check Logs in VS Code Terminal**
When you run the app, look at the Debug Console output (View → Debug Console). You'll see messages like:

```
📱 Token: ✅ Found
🚀 POST https://688b-2401-4900-1c9a-700f-c40c-75fb-3206-6bcf.ngrok-free.app/api/dashboard/
✅ Response: 200 for dashboard/
📊 Dashboard Response: {"key": "value"}
```

**Common Symbols:**
- 📱 = Token status
- 🚀 = Request being sent
- ✅ = Successful
- ❌ = Error
- 📊 = Dashboard
- 🚨 = SOS Alert
- 📡 = Network response

---

## 🔧 Troubleshooting Common Issues

### **Issue: "Failed to load dashboard data"**

Run the app and check the logs. Look for one of these:

#### A. `❌ No authentication token found`
**Problem:** You're not logged in  
**Solution:** Make sure you logged in first and the login was successful

#### B. `❌ Request timeout after 15 seconds`
**Problem:** Server is not responding (ngrok tunnel may be down)  
**Solution:**
1. Check if your ngrok tunnel is still running
2. Check if Django backend server is running
3. If ngrok tunnel died, restart it and **update the API_BASE_URL** in api_service.dart

#### C. `❌ Dashboard endpoint not found on server`
**Problem:** Your backend doesn't have `/api/dashboard/` endpoint  
**Solution:** Check your Django backend - you need to create this endpoint

#### D. `❌ Unauthorized: Token may be expired`
**Problem:** Your token is invalid or expired  
**Solution:** 
1. Log out and log in again
2. Make sure your token is being saved correctly

#### E. `❌ API Error 500: Internal Server Error`
**Problem:** Backend crashed or has a bug  
**Solution:** Check your Django backend logs for the actual error

---

### **Issue: "SOS also stopped working"**

Check logs for one of these:

#### A. `❌ SOS failed: No authentication token`
**Solution:** You must be logged in to send SOS

#### B. `❌ SOS failed with status 404`
**Problem:** Backend doesn't have `/api/alerts/panic/` endpoint  
**Solution:** Create this endpoint in your Django backend

#### C. `📡 SOS Response Status: 500`
**Problem:** Backend error when processing SOS  
**Solution:** Check Django backend logs

#### D. `⚠️ No internet connection`
**Expected:** App will try to call your emergency contact instead

---

## 🔍 Checklist to Fix All Issues

### Step 1: Verify Backend is Running
```bash
# In your Django project terminal:
python manage.py runserver
```

### Step 2: Verify ngrok Tunnel is Active
```bash
# In your ngrok terminal, you should see:
# Session Status:       connected
# Account:             your-account
# Version:             3.x.x
# Region:              in
# Forwarding:          https://xxxx.ngrok-free.app -> http://127.0.0.1:8000
```

### Step 3: Check API_BASE_URL
Open [lib/api/api_service.dart](lib/api/api_service.dart) and verify the URL:
```dart
const String API_BASE_URL = "https://688b-2401-4900-1c9a-700f-c40c-75fb-3206-6bcf.ngrok-free.app/api";
```

⚠️ **If ngrok tunnel restarted**, the URL will change! Get the new URL and update it here.

### Step 4: Test Each Endpoint

#### Test Dashboard
1. Login successfully (check token in logs)
2. Try to load dashboard
3. Look for `📊 Dashboard Response:` in logs
4. If it says "endpoint not found", create the endpoint in Django

#### Test SOS
1. Make sure you're logged in
2. Trigger SOS from the app
3. Look for `🚨 SOS Alert initiated` in logs
4. If online, should see `📡 SOS Response Status:`

---

## 📋 How to Read Error Messages Now

**Example 1:**
```
❌ ERROR at getDashboardData: Failed host lookup: 'ngrok-free' (OS Error: getaddrinfo failed, errno = 11001, address not available
```
**Meaning:** ngrok tunnel URL is invalid or DNS can't resolve it  
**Fix:** Restart ngrok, get new URL, update api_service.dart

**Example 2:**
```
❌ API Error 401: {"detail":"Invalid token"}
```
**Meaning:** Your auth token is wrong  
**Fix:** Log out and log in again

**Example 3:**
```
❌ Dashboard endpoint not found on server: /dashboard/
```
**Meaning:** Django doesn't have this endpoint  
**Fix:** Add the endpoint to your Django views

---

## 🛠️ Manual Testing (Using Postman or curl)

Test the API directly without the app:

```bash
# Get your token (do this once)
curl -X POST http://localhost:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass"}'

# Response will include: {"token":"abc123...","user":{...}}

# Now test dashboard with that token
curl -X GET http://localhost:8000/api/dashboard/ \
  -H "Authorization: Token abc123..."
```

If this works locally but not through ngrok, it's a ngrok configuration issue.

---

## 📞 When to Check Django Backend

If you see any of these in logs:
- `❌ Error 404:` - Endpoint doesn't exist in Django
- `❌ Error 500:` - Django code crashed
- `Invalid token` - Django token auth issue
- `Connection refused` - Django server not running

**Action:** Check your Django terminal for error messages and stack traces.

---

## ✅ What Happens When Everything Works

You'll see this flow in logs:

```
📱 Token: ✅ Found
🚀 POST https://...api/dashboard/
✅ Response: 200 for dashboard/
📊 Dashboard Response: {...data...}
```

And in the app:
- Dashboard loads successfully
- Data displays correctly
- SOS button works instantly

---

## 💡 Pro Tips

1. **Keep terminal window visible** while testing - logs appear in real-time
2. **Filter logs** by searching for "❌" or "✅" in VS Code
3. **Take screenshots** of error messages to share with your team
4. **Test features one at a time** - login first, then dashboard, then SOS
5. **Restart the app** if you update api_service.dart

---

## 🆘 Still Not Working?

Create a file with this info and share it:
1. Screenshot of the error message from app
2. Copy-paste of the ❌ error from logs
3. Screenshot of ngrok showing active tunnel
4. Screenshot of Django terminal showing successful startup

This tells you exactly what's wrong and where to fix it!
