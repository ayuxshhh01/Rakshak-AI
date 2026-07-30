from django.shortcuts import render
from rest_framework import generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from .serializer import (
    UserSerializer, LocationSerializer, ItinerarySerializer, GeoZoneSerializer, LoginSerializer,
    TrustedCircleMemberSerializer, SafeRouteSerializer, CheckInSerializer,
    AreaSafetyRatingSerializer, EmergencyNumberSerializer, 
    EmergencyPhraseSerializer, IncidentReportSerializer
)
from .models import (
    CustomUser, Alert, GeoZone, Itinerary,
    TrustedCircleMember, SafeRoute, CheckIn, AreaSafetyRating,
    EmergencyNumber, EmergencyPhrase, IncidentReport
)
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
import math
import logging
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .tasks import analyze_location_for_risks
from django.conf import settings
from twilio.rest import Client
from twilio.twiml.voice_response import VoiceResponse
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt

logger = logging.getLogger(__name__)
from django.urls import reverse
import json
import requests



class LoginView(APIView):
    """
    Handles user login.
    NOW, it returns the auth token AND the user's profile data.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = authenticate(
                username=serializer.validated_data['username'],
                password=serializer.validated_data['password']
            )
            if user:
                token, created = Token.objects.get_or_create(user=user)
                
                # --- THIS IS THE FIX ---
                # Serialize the user's data to send it back to the app
                user_serializer = UserSerializer(user)
                
                return Response({
                    'token': token.key,
                    'user': user_serializer.data 
                })
                # --- END OF FIX ---

            return Response({'error': 'Invalid Credentials'}, status=401)
        return Response(serializer.errors, status=400)

class RegisterView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    serializer_class = UserSerializer
    permission_classes = [AllowAny]

def check_geofence(user, lat, lon):
    all_zones = GeoZone.objects.all()
    for zone in all_zones:
        R = 6371
        dLat = math.radians(lat - zone.center_lat)
        dLon = math.radians(lon - zone.center_lon)
        a = (math.sin(dLat / 2) ** 2 +
             math.cos(math.radians(zone.center_lat)) * math.cos(math.radians(lat)) *
             math.sin(dLon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distance = R * c
        if distance < zone.radius_km:
            Alert.objects.get_or_create(
                user=user,
                alert_type="GeoFence Breach",
                defaults={'location': {'lat': lat, 'lon': lon}}
            )
            print(f"GEOFENCE ALERT for {user.username} in zone {zone.name}")
            return True
    return False 









class UpdateLocationView(APIView):
    
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        serializer = LocationSerializer(data=request.data)
        if serializer.is_valid():
            location = serializer.validated_data
            now = timezone.now()
            current_altitude = location.get('altitude')
            user.last_location = location
            user.last_location_update = timezone.now()
            
            # --- NEW: Update Location History for Journey Replay ---
            # Keep the last 30 location points (approx. 30 mins if updates are every 60s)
            history = user.location_history or []
            history.append(location)
            user.location_history = history[-30:]
            
            user.save()
            
            analyze_location_for_risks.delay(user.id, location['lat'], location['lon'])
            check_geofence(user, location['lat'], location['lon'])
            

            # --- NEW: Sudden Drop-off Detection Logic ---
            if user.last_altitude is not None and current_altitude is not None:
                altitude_change = user.last_altitude - current_altitude
                # Trigger an alert if the user drops more than 10 meters (approx. 3 floors)
                if altitude_change > 10:
                    Alert.objects.get_or_create(
                        user=user,
                        alert_type="Sudden Drop-off Detected",
                        defaults={'location': location, 'details': {'altitude_drop_meters': altitude_change}}
                    )
                    print(f"!!! SUDDEN DROP-OFF ALERT for {user.username}. Drop: {altitude_change:.2f}m !!!")
            # --- End of New Logic ---

            # Dispatch other AI tasks
            analyze_location_for_risks.delay(user.id, location['lat'], location['lon'])
            check_geofence(user, location['lat'], location['lon'])
            
            # Check for Prolonged Inactivity
            if user.last_location_update and now - user.last_location_update > timedelta(hours=1):
                 Alert.objects.get_or_create(
                    user=user,
                    alert_type="Prolonged Inactivity",
                    defaults={'location': location}
                )

            # Update user's last known state
            user.last_location_update = now
            if current_altitude is not None:
                user.last_altitude = current_altitude
            user.save()

            return Response({"status": "location updated, analysis dispatched"})
        return Response(serializer.errors, status=400)

class PanicAlertView(APIView):
    """
    Handles the SOS Panic Button press.
    It now triggers BOTH an automated voice call AND a real-time dashboard alert.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        location_serializer = LocationSerializer(data=request.data)
        
        if location_serializer.is_valid():
            alert = Alert.objects.create(
                user=user,
                alert_type="SOS",
                location=location_serializer.validated_data
                
            )
            latitude = alert.location.get("latitude")
            longitude = alert.location.get("longitude")
            maps_link = f"https://www.google.com/maps?q={latitude},{longitude}"
            sms_message = f"""
              🚨 SOS ALERT

              User: {user.username}

              Location:
                    {maps_link}

              Emergency triggered at {alert.timestamp}

              Please check immediately.
              """
            # --- Action 1: Initiate the AI Voice Call to the Emergency Contact ---
            try:
                
             if user.emergency_contact:

                client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)

                # Create Google Maps link
                latitude = alert.location.get("latitude")
                longitude = alert.location.get("longitude")

                maps_link = f"https://www.google.com/maps?q={latitude},{longitude}"

    # SMS message content
                sms_message = f"""
            🚨 SOS ALERT

            User: {user.username}

            Live Location:
            {maps_link}

            Emergency triggered at {alert.timestamp}

            Please respond immediately.
"""

    # Twilio Voice Call
                voice_url = request.build_absolute_uri(
        reverse('voice-alert-twiml', kwargs={'alert_id': alert.id})
    )

                call = client.calls.create(
                    to=user.emergency_contact,
                    from_=settings.TWILIO_PHONE_NUMBER,
                    url=voice_url
                )

                print(f"--- Initiated AI voice call to {user.emergency_contact}. Call SID: {call.sid} ---")

    # Twilio SMS
                message = client.messages.create(
                    body=sms_message,
                    from_=settings.TWILIO_PHONE_NUMBER,
                    to=user.emergency_contact
    )

                print(f"--- SMS sent successfully. Message SID: {message.sid} ---")

            except Exception as e:
                print(f"--- FAILED to initiate Twilio voice call: {e} ---")
            
            # --- Action 2: Push a Real-time Alert to the Authorities' Dashboard ---
            channel_layer = get_channel_layer()
            alert_json = {
                'alert_type': 'SOS Panic Alert',
                'user': user.username,
                'location': alert.location,
                'timestamp': str(alert.timestamp)
            }
            async_to_sync(channel_layer.group_send)(
                'alerts_group',
                {
                    'type': 'send.alert',
                    'alert': alert_json
                }
            )
            print(f"--- Pushed live alert to dashboard for user: {user.username} ---")

            return Response({"status": "alert created and call initiated", "alert_id": alert.id})
        return Response(location_serializer.errors, status=400)

class AlertActionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, alert_id):
        if not request.user.is_staff:
            return Response({"error": "Unauthorized"}, status=403)
            
        action = request.data.get("action")
        officer_id = request.data.get("officer_id")
        
        try:
            alert = Alert.objects.get(id=alert_id)
            if action == "acknowledge":
                alert.status = "Acknowledged"
                alert.save()
            elif action == "assign" and officer_id:
                officer = CustomUser.objects.get(id=officer_id, is_staff=True)
                alert.status = "Assigned"
                alert.assigned_to = officer
                alert.save()
            elif action == "resolve":
                alert.status = "Resolved"
                alert.save()
            else:
                return Response({"error": "Invalid action"}, status=400)

            return Response({"success": True, "new_status": alert.status})
        except Alert.DoesNotExist:
            return Response({"error": "Alert not found"}, status=404)
        except CustomUser.DoesNotExist:
            return Response({"error": "Officer not found"}, status=404)
        
class TouristJourneyView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        if not request.user.is_staff:
            return Response({"error": "Unauthorized"}, status=403)
        try:
            tourist = CustomUser.objects.get(id=user_id, is_staff=False)
            return Response({"journey": tourist.location_history})
        except CustomUser.DoesNotExist:
            return Response({"error": "Tourist not found"}, status=404)
# --- View to Generate the AI Voice Message (TwiML) ---
@csrf_exempt
def voice_alert_twiml(request, alert_id):
    """
    This view is called by Twilio during the phone call. It generates the
    spoken AI message based on the alert details.
    """
    try:
        alert = Alert.objects.get(id=alert_id)
        user = alert.user
        location = alert.location

        message = f"""
        This is an automated emergency alert from the Smart Tourist Safety System.
        An SOS has been triggered by {user.username}.
        Repeat. An emergency alert has been triggered by {user.username}.
        Last known location was latitude {location.get('lat')}, longitude {location.get('lon')}.
        Please check on them immediately.
        """
        
        response = VoiceResponse()
        response.say(message, voice='alice', language='en-IN')
        response.hangup()

        return HttpResponse(str(response), content_type='text/xml')

    except Alert.DoesNotExist:
        response = VoiceResponse()
        response.say("Sorry, an error occurred and we could not find the alert details.", voice='alice', language='en-IN')
        return HttpResponse(str(response), content_type='text/xml')

class DashboardDataView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        user = request.user
        try:
            itinerary = Itinerary.objects.filter(user=user).latest('id')
            itinerary_data = ItinerarySerializer(itinerary).data['plan_data']
        except Itinerary.DoesNotExist:
            itinerary_data = {}
        data = { "safety_score": user.safety_score, "itinerary": itinerary_data }
        return Response(data)

class ItineraryGeneratorView(APIView):
    """
    Accepts user preferences and uses a generative AI model to create a smart itinerary.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        destination = request.data.get('destination')
        duration = request.data.get('duration')
        budget = request.data.get('budget')
        
        print(f"[DEBUG] ItineraryGeneratorView called for user '{user.username}' with destination: '{destination}'")

        if not all([destination, duration, budget]):
            return Response({"error": "Destination, duration, and budget are required."}, status=400)

        prompt = f"""
        Act as an expert local tour guide for {destination}, India.
        Create a detailed and practical {duration}-day travel itinerary for a tourist with a {budget} budget.
        Suggest famous and relevant tourist spots, including a mix of historical sites, nature, and unique local food experiences.
        For each activity, provide a suggested time and a compelling one-sentence description.
        Structure the output as a clean JSON object only. The main keys must be "day_1", "day_2", etc.
        Each day must be an array of activity objects, where each object has three keys: "time", "activity", and "icon".
        Choose an appropriate icon name from this list: 'account_balance', 'restaurant', 'fort', 'directions_car', 'hotel', 'park', 'camera_alt'.
        Do not include any text outside of the JSON object.
        """

        print("[DEBUG] Sending request to Gemini API...")
        apiKey = "AIzaSyAneEmr1icoMrZXUQbUtHU_fuedwdcO-a8" 
        url = url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={apiKey}"

        schema = {"type": "OBJECT", "properties": {}, "required": []}
        try:
            num_duration = int(duration)
        except (ValueError, TypeError):
            return Response({"error": "Duration must be a valid number."}, status=400)
            
        for i in range(1, num_duration + 1):
            day_key = f"day_{i}"
            schema["properties"][day_key] = {
                "type": "ARRAY", "items": {
                    "type": "OBJECT", "properties": {
                        "time": {"type": "STRING"}, "activity": {"type": "STRING"}, "icon": {"type": "STRING"},
                    }, "required": ["time", "activity", "icon"]
                }
            }
            schema["required"].append(day_key)

        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"response_mime_type": "application/json", "response_schema": schema}
        }

        try:
            response = requests.post(url, json=payload)
            print(f"[DEBUG] Gemini API Response Status Code: {response.status_code}")
            response.raise_for_status()
            
            result_json = response.json()
            ai_text_response = result_json.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', '{}')
            ai_generated_plan = json.loads(ai_text_response)

            print("[DEBUG] Successfully received and parsed itinerary from Gemini.")

            itinerary, created = Itinerary.objects.update_or_create(
                user=user, defaults={'plan_data': ai_generated_plan}
            )
            print(f"[DEBUG] Itinerary saved to database for user '{user.username}'.")
            
            serializer = ItinerarySerializer(itinerary)
            return Response(serializer.data)

        except requests.exceptions.RequestException as e:
            print(f"[DEBUG] Gemini API call FAILED: {e}")
            return Response({"error": "Failed to connect to the AI service."}, status=500)
        except (KeyError, IndexError, json.JSONDecodeError):
             print("[DEBUG] Gemini API response parsing FAILED. Raw response text:", response.text)
             return Response({"error": "AI service returned an invalid format."}, status=500)

class ItineraryView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        itinerary, created = Itinerary.objects.get_or_create(
            user=request.user,
            defaults={'plan_data': {}}
        )
        serializer = ItinerarySerializer(itinerary)
        return Response(serializer.data)

class GeoZoneView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    queryset = GeoZone.objects.all()
    serializer_class = GeoZoneSerializer


# ============= AI SERVICE ENDPOINT PROXY =============

class PredictRiskZonesView(APIView):
    """
    Proxy endpoint to AI service for predicting risk zones
    Risk predictions are public data, so no authentication required
    """
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            # Call AI service endpoint
            ai_service_url = 'http://localhost:8001/predict-risk-zones'
            response = requests.post(ai_service_url, timeout=10)
            
            if response.status_code == 200:
                return Response(response.json())
            else:
                # Fallback: return empty risk zones if AI service unavailable
                print(f"⚠️ AI service returned {response.status_code}")
                return Response([], status=200)
        except Exception as e:
            print(f"⚠️ AI service unavailable: {e}")
            # Return empty list instead of erroring out
            return Response([], status=200)


# ============= NEW VIEWS FOR 7 TOURIST SAFETY FEATURES =============

# 1. TRUSTED CIRCLE VIEW
class TrustedCircleView(generics.ListCreateAPIView):
    """Get list of trusted circle members or add a new one"""
    permission_classes = [IsAuthenticated]
    serializer_class = TrustedCircleMemberSerializer

    def get_queryset(self):
        return TrustedCircleMember.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class TrustedCircleDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Get, update, or delete a trusted circle member"""
    permission_classes = [IsAuthenticated]
    serializer_class = TrustedCircleMemberSerializer

    def get_queryset(self):
        return TrustedCircleMember.objects.filter(user=self.request.user)


class SharedLocationView(APIView):
    """Get the current user's location to share with trusted circle"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        return Response([{
            'user_id': user.id,
            'username': user.username,
            'location': getattr(user, 'last_location', None),
            'timestamp': getattr(user, 'last_location_update', None),
            'safety_score': user.safety_score
        }])


# 2. SAFE ROUTE VIEW
class SafeRouteView(generics.ListCreateAPIView):
    """Get list of safe routes or generate new one from itinerary"""
    permission_classes = [IsAuthenticated]
    serializer_class = SafeRouteSerializer

    def get_queryset(self):
        return SafeRoute.objects.filter(user=self.request.user)

    def get(self, request, *args, **kwargs):
        """Get routes - auto-generate from itinerary if requested"""
        from_itinerary = request.query_params.get('from_itinerary', 'false').lower() == 'true'
        
        if from_itinerary:
            # Generate routes from user's latest itinerary
            try:
                itinerary = Itinerary.objects.filter(user=request.user).latest('id')
                if itinerary:
                    from .external_apis import SafeRouteService
                    
                    # Get user's current location if provided
                    user_lat = request.query_params.get('lat')
                    user_lon = request.query_params.get('lon')
                    user_location = None
                    if user_lat and user_lon:
                        try:
                            user_location = {'lat': float(user_lat), 'lon': float(user_lon)}
                        except:
                            pass
                    
                    # Generate routes from itinerary
                    routes_data = SafeRouteService.generate_routes_from_itinerary(
                        itinerary.plan_data,
                        user_location
                    )
                    
                    # Create SafeRoute objects
                    created_routes = []
                    for route_data in routes_data:
                        try:
                            route = SafeRoute.objects.create(
                                user=request.user,
                                **route_data
                            )
                            created_routes.append(route)
                        except Exception as e:
                            logger.error(f'Error creating route: {e}')
                    
                    serializer = SafeRouteSerializer(created_routes, many=True)
                    return Response(serializer.data)
            except Itinerary.DoesNotExist:
                pass
        
        # Return saved routes
        return super().get(request, *args, **kwargs)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def post(self, request, *args, **kwargs):
        """Generate safe routes from itinerary or from start/end locations"""
        import logging
        from .external_apis import SafeRouteService
        from .models import Itinerary
        
        logger = logging.getLogger(__name__)
        
        start = request.data.get('start_location')
        end = request.data.get('end_location')
        
        # If no start/end provided, generate from user's itinerary
        if not start or not end:
            try:
                itinerary = Itinerary.objects.filter(user=request.user).latest('id')
                
                # Get user's current location if provided
                user_lat = request.data.get('lat')
                user_lon = request.data.get('lon')
                user_location = None
                if user_lat and user_lon:
                    try:
                        user_location = {'lat': float(user_lat), 'lon': float(user_lon)}
                    except:
                        pass
                
                # Generate routes from itinerary
                routes_data = SafeRouteService.generate_routes_from_itinerary(
                    itinerary.plan_data,
                    user_location
                )
                
                if not routes_data:
                    return Response(
                        {'error': 'Could not generate routes from itinerary'},
                        status=400
                    )
                
                # Create SafeRoute objects
                created_routes = []
                for route_data in routes_data:
                    try:
                        route = SafeRoute.objects.create(
                            user=request.user,
                            **route_data
                        )
                        created_routes.append(route)
                    except Exception as e:
                        logger.error(f'Error creating route: {e}')
                
                serializer = SafeRouteSerializer(created_routes, many=True)
                return Response(serializer.data, status=201)
                
            except Itinerary.DoesNotExist:
                return Response(
                    {'error': 'No itinerary found. Please create an itinerary first.'},
                    status=400
                )
            except Exception as e:
                logger.error(f'Error generating routes from itinerary: {e}')
                return Response(
                    {'error': f'Error generating routes: {str(e)}'},
                    status=500
                )
        
        # If start/end provided, create route directly
        danger_zones = GeoZone.objects.all()
        safety_score = 85  # Default
        
        # Create route
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(user=self.request.user, safety_score=safety_score)
        return Response(serializer.data, status=201)


class SafeRouteDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Get, update, or delete a safe route"""
    permission_classes = [IsAuthenticated]
    serializer_class = SafeRouteSerializer

    def get_queryset(self):
        return SafeRoute.objects.filter(user=self.request.user)


# 3. CHECK-IN VIEW
class CheckInView(generics.ListCreateAPIView):
    """Get list of check-ins or create new one"""
    permission_classes = [IsAuthenticated]
    serializer_class = CheckInSerializer

    def get_queryset(self):
        return CheckIn.objects.filter(user=self.request.user)

    def post(self, request, *args, **kwargs):
        # Transform request data to match the model
        data = request.data.copy()
        if 'lat' in data and 'lon' in data:
            data['location'] = {
                'lat': float(data.get('lat')),
                'lon': float(data.get('lon'))
            }
        
        serializer = self.get_serializer(data=data)
        if not serializer.is_valid():
            print(f'CheckIn validation errors: {serializer.errors}')
            return Response(serializer.errors, status=400)
        
        check_in = serializer.save(user=self.request.user)
        return Response(CheckInSerializer(check_in).data, status=201)

    def perform_create(self, serializer):
        # Note: PostMethod overrides this, but kept for backward compatibility
        serializer.save(user=self.request.user)


class PublicCheckInsView(generics.ListAPIView):
    """Get public and trusted circle check-ins from other tourists"""
    permission_classes = [IsAuthenticated]
    serializer_class = CheckInSerializer

    def get_queryset(self):
        return CheckIn.objects.filter(visibility__in=['Public', 'Trusted Circle'])


# 4. AREA SAFETY RATING VIEW
class AreaSafetyRatingView(generics.ListAPIView):
    """Get real-time safety ratings for areas using official crime data + user reports"""
    permission_classes = [IsAuthenticated]
    serializer_class = AreaSafetyRatingSerializer

    def get_queryset(self):
        return AreaSafetyRating.objects.all()

    def get(self, request):
        from .external_apis import CrimeDataService
        
        # Get location parameters
        lat = request.query_params.get('lat')
        lon = request.query_params.get('lon')
        city = request.query_params.get('city', '')
        
        if not lat or not lon:
            # No location provided, return static data
            return Response(AreaSafetyRatingSerializer(self.get_queryset(), many=True).data)
        
        try:
            lat = float(lat)
            lon = float(lon)
            
            # Get REAL-TIME safety data from crime statistics + user reports
            safety_data = CrimeDataService.get_area_safety(lat, lon, city)
            
            return Response({
                'location': {'lat': lat, 'lon': lon},
                'safety_score': safety_data['safety_score'],
                'crime_rate': safety_data['crime_rate'],
                'warning_level': safety_data.get('warning_level', 'UNKNOWN'),
                'recent_incidents': safety_data['recent_incidents_count'],
                'sources': safety_data['sources'],
                'data_type': 'real-time',
                'last_updated': str(safety_data.get('last_updated'))
            })
        
        except ValueError:
            return Response({'error': 'Invalid coordinates'}, status=400)
        except Exception as e:
            import logging
            logging.error(f'Error fetching area safety: {e}')
            return Response({'error': 'Unable to fetch safety data'}, status=500)


# 5. EMERGENCY NUMBER VIEW
class EmergencyNumberView(generics.ListAPIView):
    """Get REAL government emergency numbers for a location"""
    permission_classes = [IsAuthenticated]
    serializer_class = EmergencyNumberSerializer
    
    def get_queryset(self):
        country = self.request.query_params.get('country')
        city = self.request.query_params.get('city')
        service_type = self.request.query_params.get('service_type')
        
        queryset = EmergencyNumber.objects.all()
        if country:
            queryset = queryset.filter(country=country)
        if city:
            queryset = queryset.filter(city=city)
        if service_type:
            queryset = queryset.filter(service_type=service_type)
        
        return queryset
    
    def get(self, request, *args, **kwargs):
        from .external_apis import GovernmentEmergencyService
        
        country = request.query_params.get('country', 'India')
        state = request.query_params.get('state', '')
        
        # Get government verified emergency numbers
        numbers = GovernmentEmergencyService.get_real_time_emergency_numbers(country, state)
        
        if not numbers:
            # Fallback to database
            return super().get(request, *args, **kwargs)
        
        return Response(numbers)


# 6. EMERGENCY PHRASE VIEW
class EmergencyPhraseView(generics.ListAPIView):
    """Get emergency phrases for a language"""
    permission_classes = [IsAuthenticated]
    serializer_class = EmergencyPhraseSerializer

    def get_queryset(self):
        language = self.request.query_params.get('language', 'English')
        return EmergencyPhrase.objects.filter(language=language)


# 7. INCIDENT REPORT VIEW
class IncidentReportView(generics.ListCreateAPIView):
    """Get list of incident reports or create new one"""
    permission_classes = [IsAuthenticated]
    serializer_class = IncidentReportSerializer

    def get_queryset(self):
        # Option: return all reports or just user's reports
        return IncidentReport.objects.all().order_by('-timestamp')

    def post(self, request, *args, **kwargs):
        # Transform request data to match the model
        data = request.data.copy()
        if 'lat' in data and 'lon' in data:
            data['location'] = {
                'lat': data.get('lat'),
                'lon': data.get('lon')
            }
        
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        report = serializer.save(reported_by=self.request.user)
        
        # Update affected area safety rating
        location = report.location
        area_rating, created = AreaSafetyRating.objects.get_or_create(
            location_name=report.location_name,
            defaults={
                'latitude': location.get('lat'),
                'longitude': location.get('lon'),
                'overall_rating': Decimal('5.0')
            }
        )
        # Decrease rating based on severity
        if report.severity == 'High':
            area_rating.overall_rating = max(Decimal(0), area_rating.overall_rating - Decimal(1))
        elif report.severity == 'Medium':
            area_rating.overall_rating = max(Decimal(0), area_rating.overall_rating - Decimal('0.5'))
        area_rating.user_reports_count += 1
        area_rating.save()
        
        return Response(IncidentReportSerializer(report).data, status=201)

    def perform_create(self, serializer):
        # Note: Post method overrides this, but kept for backward compatibility
        serializer.save(reported_by=self.request.user)


class IncidentReportDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Get, update, or delete an incident report"""
    permission_classes = [IsAuthenticated]
    serializer_class = IncidentReportSerializer

    def get_queryset(self):
        return IncidentReport.objects.all()


class IncidentReportLikeView(APIView):
    """Like/upvote an incident report"""
    permission_classes = [IsAuthenticated]

    def post(self, request, report_id):
        try:
            report = IncidentReport.objects.get(id=report_id)
            report.helpful_count += 1
            report.save()
            return Response({'helpful_count': report.helpful_count})
        except IncidentReport.DoesNotExist:
            return Response({'error': 'Report not found'}, status=404)


class MedicalFacilitiesView(APIView):
    """Get REAL medical facilities near user location from Google Places API"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .external_apis import GooglePlacesService
        
        lat = request.query_params.get('lat')
        lon = request.query_params.get('lon')
        radius = request.query_params.get('radius', 5000)  # meters
        
        if not lat or not lon:
            return Response({'error': 'Location (lat, lon) parameters required'}, status=400)
        
        try:
            lat = float(lat)
            lon = float(lon)
            radius = int(radius)
            
            # Get REAL medical facilities from Google Places API
            facilities = GooglePlacesService.search_nearby_hospitals(lat, lon, radius)
            
            return Response({
                'count': len(facilities),
                'location': {'lat': lat, 'lon': lon},
                'facilities': facilities,
                'data_type': 'real-time',
                'source': 'google_places_api'
            })
        
        except (ValueError, TypeError) as e:
            return Response({'error': f'Invalid parameters: {str(e)}'}, status=400)
        except Exception as e:
            import logging
            logging.error(f'Error fetching medical facilities: {e}')
            return Response({'error': 'Unable to fetch medical facilities. Please try again.'}, status=500)


class EmergencyServicesView(APIView):
    """Get REAL emergency services (police, fire, ambulance) near user location"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .external_apis import GooglePlacesService
        
        lat = request.query_params.get('lat')
        lon = request.query_params.get('lon')
        service_type = request.query_params.get('type', 'police')  # police, fire, ambulance
        radius = request.query_params.get('radius', 10000)  # meters (larger for emergencies)
        
        if not lat or not lon:
            return Response({'error': 'Location (lat, lon) parameters required'}, status=400)
        
        try:
            lat = float(lat)
            lon = float(lon)
            radius = int(radius)
            
            # Get REAL emergency services from Google Places API
            services = GooglePlacesService.search_emergency_services(lat, lon, service_type)
            
            return Response({
                'count': len(services),
                'service_type': service_type,
                'location': {'lat': lat, 'lon': lon},
                'services': services,
                'data_type': 'real-time',
                'source': 'google_places_api'
            })
        
        except (ValueError, TypeError) as e:
            return Response({'error': f'Invalid parameters: {str(e)}'}, status=400)
        except Exception as e:
            import logging
            logging.error(f'Error fetching emergency services: {e}')
            return Response({'error': 'Unable to fetch emergency services'}, status=500)


# Import new serializers at top of file
from .serializer import (
    TrustedCircleMemberSerializer, SafeRouteSerializer, CheckInSerializer,
    AreaSafetyRatingSerializer, EmergencyNumberSerializer, 
    EmergencyPhraseSerializer, IncidentReportSerializer
)