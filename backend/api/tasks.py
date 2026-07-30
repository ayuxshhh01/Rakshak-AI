# in api/tasks.py
from backend.celery import app
import requests
import json
import math
from .models import Alert, CustomUser

AI_SERVICE_URL = "http://127.0.0.1:8001"

# ... (keep the haversine_distance function as it is) ...
def haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)
    a = (math.sin(dLat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dLon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# --- CHANGE 1: Modified function signature ---
@app.task
def analyze_location_for_risks(user_id, lat, lon):
    """
    An asynchronous task that calls the AI service to check for risks.
    Accepts lat and lon as separate, simple arguments.
    """
    location_data = {"lat": lat, "lon": lon} # Reconstruct the dictionary here
    print(f"--- THIS LOG IS FROM THE CELERY WORKER for user {user_id} at {location_data} ---")

    try:
        user = CustomUser.objects.get(id=user_id)
    except CustomUser.DoesNotExist:
        print(f"Celery Task: User with id {user_id} not found. Aborting.")
        return "User not found"

    # --- Call the AI Service Endpoint ---
    try:
        response = requests.post(f"{AI_SERVICE_URL}/predict-risk-zones", json=location_data)
        response.raise_for_status()

        risk_data = response.json()
        print(f"Celery Worker: Received AI response: {risk_data}")

        # ... (rest of the logic is the same)
        hotspots = risk_data.get("predicted_hotspots", [])
        for hotspot in hotspots:
            if haversine_distance(lat, lon, hotspot['lat'], hotspot['lon']) < 0.2:
                print(f"RISK DETECTED BY WORKER: User {user.username} is inside a predicted high-risk zone.")
                Alert.objects.create(
                    user=user,
                    alert_type="AI Predicted Risk",
                    location=location_data,
                    details={"message": "User entered an area with a high concentration of past incidents."}
                )
                break
    except requests.exceptions.RequestException as e:
        print(f"Celery Worker: Could not connect to AI service: {e}")

    return "Analysis complete by worker"