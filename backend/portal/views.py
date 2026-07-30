from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from api.models import Alert, CustomUser, GeoZone, Itinerary
from django.utils import timezone
from datetime import timedelta, datetime
import json
import logging

logger = logging.getLogger(__name__)

# This class teaches the json.dumps function how to handle datetime objects.
class DateTimeEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime):
            return o.isoformat()
        if isinstance(o, (list, dict)):
            return super().default(o)
        return str(o)


def dashboard_view(request):
    """
    Render the dashboard with live map, statistics, alerts, and tourist management
    Uses all available view functions from portal/views.py
    """
    # Fetch geozones data
    geozones = GeoZone.objects.all()
    geozones_data = []
    for zone in geozones:
        try:
            geozones_data.append({
                "id": zone.id,
                "name": zone.name,
                "zone_type": zone.zone_type,
                "lat": float(zone.center_lat),
                "lon": float(zone.center_lon),
                "radius": float(zone.radius_km) * 1000
            })
        except (TypeError, ValueError, AttributeError) as e:
            logger.error(f"Error processing geozone {zone.id}: {e}")
            continue
    
    context = {
        'geozones_json': json.dumps(geozones_data, cls=DateTimeEncoder),
    }
    
    return render(request, 'dashboard.html', context)


def get_live_tourists(request):
    """
    API endpoint to fetch live tourist locations (for AJAX updates)
    Returns JSON data that can be used to update the map in real-time
    """
    # if not request.user.is_staff:
    #     return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    all_tourists = CustomUser.objects.filter(is_staff=False)
    tourists_data = []
    
    for tourist in all_tourists:
        try:
            # Get the most recent location from location_history
            lat = 22.5726
            lon = 88.3639
            
            if tourist.location_history and len(tourist.location_history) > 0:
                last_location = tourist.location_history[-1]
                
                if isinstance(last_location, dict):
                    lat = float(last_location.get('lat', last_location.get('latitude', 22.5726)))
                    lon = float(last_location.get('lon', last_location.get('longitude', 88.3639)))
                elif isinstance(last_location, list) and len(last_location) >= 2:
                    lat = float(last_location[0])
                    lon = float(last_location[1])
                
            # Check for recent SOS alerts
            has_recent_sos = Alert.objects.filter(
                user=tourist,
                alert_type__icontains='SOS',
                timestamp__gte=timezone.now() - timedelta(hours=1)
            ).exists()
            
            # Get contact info
            phone_number = tourist.phone_number or 'N/A'
            safety_score = getattr(tourist, 'safety_score', 85)
            
            # Add all tourists
            tourists_data.append({
                "id": tourist.id,
                "username": tourist.username,
                "first_name": tourist.first_name,
                "email": tourist.email,
                "phone_number": phone_number,
                "status": "alert" if has_recent_sos else "safe",
                "safety_score": safety_score,
                "active_alerts": Alert.objects.filter(user=tourist, status__icontains='active').count(),
                "last_location": {
                    "lat": lat,
                    "lon": lon
                },
                "last_update": timezone.now().isoformat()
            })
        except Exception as e:
            print(f"Error processing tourist {tourist.username}: {e}")
            continue
    
    return JsonResponse({'status': 'success', 'tourists': tourists_data}, encoder=DateTimeEncoder)



def get_activity_stats(request):
    """
    API endpoint to fetch real-time activity statistics
    Returns dashboard statistics for the Activity Monitor
    """
    # if not request.user.is_staff:
    #     return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    try:
        # Get all active tourists
        all_tourists = CustomUser.objects.filter(is_staff=False)
        total_tourists = all_tourists.count()
        
        # Get tourists with location history (online/active)
        active_tourists = all_tourists.filter(location_history__isnull=False).exclude(location_history=[]).count()
        
        # Get recent alerts (last 24 hours)
        recent_alerts = Alert.objects.filter(
            timestamp__gte=timezone.now() - timedelta(hours=24)
        ).count()
        
        # Get active SOS alerts
        active_sos = Alert.objects.filter(
            alert_type__icontains='SOS',
            timestamp__gte=timezone.now() - timedelta(hours=1),
            status__icontains='active'
        ).count()
        
        # Get geofence violations
        geofence_violations = Alert.objects.filter(
            alert_type__icontains='GeoFence',
            timestamp__gte=timezone.now() - timedelta(hours=24)
        ).count()
        
        # Get safe tourists count
        safe_tourists = total_tourists - active_sos
        
        # Get alerts by type
        alerts_by_type = {}
        for alert_type in ['SOS', 'GeoFence', 'Risk']:
            count = Alert.objects.filter(
                alert_type__icontains=alert_type,
                timestamp__gte=timezone.now() - timedelta(hours=24)
            ).count()
            alerts_by_type[alert_type] = count
        
        # Get recent activities (last 10 alerts)
        recent_activity = Alert.objects.select_related('user').order_by('-timestamp')[:10]
        activities = []
        for alert in recent_activity:
            activities.append({
                'type': alert.alert_type,
                'user': alert.user.username,
                'time': alert.timestamp.strftime('%H:%M:%S'),
                'status': alert.status
            })
        
        stats = {
            'total_tourists': total_tourists,
            'active_tourists': active_tourists,
            'safe_tourists': safe_tourists,
            'recent_alerts_24h': recent_alerts,
            'active_sos': active_sos,
            'geofence_violations': geofence_violations,
            'alerts_by_type': alerts_by_type,
            'recent_activities': activities,
            'timestamp': timezone.now().isoformat()
        }
        
        return JsonResponse(stats)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)



def get_alert_history(request):
    """
    API endpoint to fetch complete alert history with filtering
    Supports filtering by alert type, status, and date range
    """
    # if not request.user.is_staff:
    #     return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    try:
        # Get filter parameters
        alert_type = request.GET.get('type', '')
        status = request.GET.get('status', '')
        days = int(request.GET.get('days', 7))  # Default to last 7 days
        
        # Build query
        query = Alert.objects.select_related('user').order_by('-timestamp')
        
        # Apply filters
        if alert_type:
            query = query.filter(alert_type__icontains=alert_type)
        
        if status:
            query = query.filter(status__icontains=status)
        
        if days > 0:
            query = query.filter(
                timestamp__gte=timezone.now() - timedelta(days=days)
            )
        
        # Limit results
        limit = int(request.GET.get('limit', 100))
        alerts = query[:limit]
        
        # Format the response
        alerts_data = []
        for alert in alerts:
            # Parse location
            if alert.location:
                if isinstance(alert.location, str):
                    location_data = json.loads(alert.location)
                else:
                    location_data = alert.location
                alert_lat = float(location_data.get('lat', 22.5726))
                alert_lon = float(location_data.get('lon', 88.3639))
            else:
                alert_lat = 22.5726
                alert_lon = 88.3639
            
            alerts_data.append({
                'id': alert.id,
                'type': alert.alert_type,
                'user': alert.user.username,
                'timestamp': alert.timestamp.isoformat(),
                'status': alert.status,
                'location': {
                    'lat': alert_lat,
                    'lon': alert_lon
                },
                'heart_rate': alert.heart_rate,
                'details': alert.details
            })
        
        return JsonResponse({
            'total': len(alerts_data),
            'alerts': alerts_data
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)



def get_alert_details(request, alert_id):
    """
    API endpoint to fetch detailed information about a specific alert
    Used when clicking on an alert card to show the modal
    """
    # if not request.user.is_staff:
    #     return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    try:
        alert = Alert.objects.select_related('user').get(id=alert_id)
        
        # Get itinerary
        try:
            itinerary_obj = Itinerary.objects.get(user=alert.user)
            if isinstance(itinerary_obj.plan_data, str):
                itinerary_plan = json.loads(itinerary_obj.plan_data)
            else:
                itinerary_plan = itinerary_obj.plan_data
                
            if not isinstance(itinerary_plan, dict):
                itinerary_plan = {"day_1": [{"time": "N/A", "activity": str(itinerary_plan)}]}
        except Itinerary.DoesNotExist:
            itinerary_plan = {"day_1": [{"time": "N/A", "activity": "No itinerary available"}]}
        except (json.JSONDecodeError, TypeError):
            itinerary_plan = {"day_1": [{"time": "N/A", "activity": "Error loading itinerary"}]}
        
        # Parse location
        if alert.location:
            if isinstance(alert.location, str):
                location_data = json.loads(alert.location)
            else:
                location_data = alert.location
            alert_lat = float(location_data.get('lat', location_data.get('latitude', 22.5726)))
            alert_lon = float(location_data.get('lon', location_data.get('longitude', 88.3639)))
        else:
            alert_lat = 22.5726
            alert_lon = 88.3639
        
        alert_data = {
            'id': alert.id,
            'alert_type': alert.alert_type,
            'timestamp': alert.timestamp,
            'status': alert.status,
            'location': {
                'lat': alert_lat,
                'lon': alert_lon
            },
            'user': {
                'username': alert.user.username,
                'phone': alert.user.phone_number or 'N/A',
                'emergency_contact': alert.user.emergency_contact or 'N/A',
            },
            'itinerary': itinerary_plan,
            'heart_rate': alert.heart_rate,
            'details': alert.details
        }
        
        return JsonResponse(alert_data, encoder=DateTimeEncoder)
    except Alert.DoesNotExist:
        return JsonResponse({'error': 'Alert not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

#AIzaSyDUYui_-ZIuFymhmFYFi7dK3Nld-oCYL7A



def get_tourist_profile(request, tourist_id):
    """
    Get detailed profile of a tourist including location history, itinerary, and contacts
    """
    # if not request.user.is_staff:
    #     return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    try:
        tourist = CustomUser.objects.get(id=tourist_id, is_staff=False)
        
        # Get itinerary
        try:
            itinerary_obj = Itinerary.objects.get(user=tourist)
            if isinstance(itinerary_obj.plan_data, str):
                itinerary_plan = json.loads(itinerary_obj.plan_data)
            else:
                itinerary_plan = itinerary_obj.plan_data
        except Itinerary.DoesNotExist:
            itinerary_plan = {}
        except (json.JSONDecodeError, TypeError):
            itinerary_plan = {}
        
        # Get last 30 location history entries
        location_history = tourist.location_history[-30:] if tourist.location_history else []
        
        # Get recent alerts for this tourist
        recent_alerts = Alert.objects.filter(user=tourist).order_by('-timestamp')[:10]
        alerts_list = []
        for alert in recent_alerts:
            alerts_list.append({
                'id': alert.id,
                'type': alert.alert_type,
                'status': alert.status,
                'timestamp': alert.timestamp.isoformat(),
                'details': alert.details
            })
        
        profile_data = {
            'id': tourist.id,
            'username': tourist.username,
            'email': tourist.email,
            'phone_number': tourist.phone_number or 'Not provided',
            'emergency_contact': tourist.emergency_contact or 'Not provided',
            'safety_score': tourist.safety_score,
            'last_location': tourist.last_location if hasattr(tourist, 'last_location') else None,
            'last_location_update': tourist.last_location_update.isoformat() if tourist.last_location_update else None,
            'location_history': location_history,
            'itinerary': itinerary_plan,
            'recent_alerts': alerts_list
        }
        
        return JsonResponse(profile_data)
    except CustomUser.DoesNotExist:
        return JsonResponse({'error': 'Tourist not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)



def update_alert_status(request, alert_id):
    """
    Update alert status (safe, in danger, resolved, etc.)
    """
    # if not request.user.is_staff:
    #     return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        status = data.get('status')
        comments = data.get('comments', '')
        
        alert = Alert.objects.get(id=alert_id)
        alert.status = status
        if comments:
            if alert.details:
                alert.details['officer_comments'] = comments
            else:
                alert.details = {'officer_comments': comments}
        alert.save()
        
        return JsonResponse({
            'success': True,
            'message': f'Alert status updated to {status}',
            'alert_id': alert.id,
            'new_status': alert.status
        })
    except Alert.DoesNotExist:
        return JsonResponse({'error': 'Alert not found'}, status=404)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)



def file_efir(request):
    """
    File an electronic FIR (First Information Report) for a tourist
    """
    # if not request.user.is_staff:
    #     return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        tourist_id = data.get('tourist_id')
        incident_type = data.get('incident_type')
        description = data.get('description')
        location = data.get('location', {})
        witnesses = data.get('witnesses', [])
        
        if not all([tourist_id, incident_type, description]):
            return JsonResponse({'error': 'Missing required fields: tourist_id, incident_type, description'}, status=400)
        
        tourist = CustomUser.objects.get(id=tourist_id, is_staff=False)
        
        # Use provided location or get last known location
        if not location or (location.get('lat') == 0 and location.get('lon') == 0):
            if tourist.location_history and len(tourist.location_history) > 0:
                last_loc = tourist.location_history[-1]
                location = {
                    'lat': last_loc.get('lat', 0),
                    'lon': last_loc.get('lon', 0)
                }
            else:
                location = {'lat': 0, 'lon': 0}
        
        # Create an alert that serves as the FIR record
        efir_details = {
            'incident_type': incident_type,
            'description': description,
            'witnesses': witnesses,
            'filing_officer': request.user.username,
            'filing_timestamp': timezone.now().isoformat(),
            'efir_number': f"EFIR-{timezone.now().strftime('%Y%m%d%H%M%S')}-{tourist.id}",
            'case_status': 'Filed'
        }
        
        alert = Alert.objects.create(
            user=tourist,
            alert_type='e-FIR',
            location=location,
            details=efir_details,
            status='Filed'
        )
        
        return JsonResponse({
            'success': True,
            'message': 'e-FIR filed successfully',
            'efir_number': efir_details['efir_number'],
            'alert_id': alert.id
        })
    except CustomUser.DoesNotExist:
        return JsonResponse({'error': 'Tourist not found'}, status=404)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)



def get_location_history(request, tourist_id):
    """
    Get full location history of a tourist with timestamps and altitude info
    """
    # if not request.user.is_staff:
    #     return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    try:
        tourist = CustomUser.objects.get(id=tourist_id, is_staff=False)
        location_history = tourist.location_history or []
        
        # Ensure location history items have all required fields
        formatted_locations = []
        for idx, loc in enumerate(location_history):
            if isinstance(loc, dict):
                formatted_loc = {
                    'lat': loc.get('lat', 0),
                    'lon': loc.get('lon', 0),
                    'altitude': loc.get('altitude'),
                    'timestamp': loc.get('timestamp', f"Point {idx + 1}")
                }
                formatted_locations.append(formatted_loc)
        
        return JsonResponse({
            'tourist_id': tourist.id,
            'username': tourist.username,
            'total_points': len(formatted_locations),
            'locations': formatted_locations
        })
    except CustomUser.DoesNotExist:
        return JsonResponse({'error': 'Tourist not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ========== NEW API ENDPOINTS FOR ADVANCED FEATURES ==========

def get_responder_assignments(request):
    """
    Get all active responder assignments with real data from alerts and staff assignments
    Returns: List of alerts with assignment status
    """
    try:
        # Get all unresolved alerts
        unresolved_alerts = Alert.objects.select_related('user', 'assigned_to').filter(
            status__in=['Unassigned', 'Acknowledged', 'Assigned']  
        ).order_by('-timestamp')[:20]
        
        assignments = []
        for alert in unresolved_alerts:
            assignments.append({
                'alert_id': alert.id,
                'alert_type': alert.alert_type,
                'tourist': alert.user.username,
                'location': alert.location,
                'timestamp': alert.timestamp.isoformat(),
                'responder': alert.assigned_to.username if alert.assigned_to else 'Unassigned',
                'status': alert.status,
                'eta': '-- minutes',  # Would be calculated from API
                'phone': alert.user.phone_number or 'N/A',
                'emergency_contact': alert.user.emergency_contact or 'N/A'
            })
        
        return JsonResponse({
            'total': len(assignments),
            'assignments': assignments,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def get_incident_reports(request):
    """
    Get all e-FIR incident reports filed by authorities
    Returns: List of FIR records with details
    """
    try:
        # Get all alerts with type 'e-FIR' or matching efir patterns
        efir_alerts = Alert.objects.select_related('user').filter(
            alert_type__icontains='e-FIR'
        ).order_by('-timestamp')[:50]
        
        incidents = []
        for alert in efir_alerts:
            details = alert.details or {}
            
            # Determine severity based on description
            description = details.get('description', '')
            if any(word in description.lower() for word in ['critical', 'severe', 'injury']):
                severity = 'Critical'
            elif any(word in description.lower() for word in ['emergency', 'urgent', 'assault']):
                severity = 'High'
            elif any(word in description.lower() for word in ['lost', 'minor']):
                severity = 'Medium'
            else:
                severity = 'Low'
            
            incidents.append({
                'id': details.get('efir_number', f"FIR-{alert.id:06d}"),
                'type': details.get('incident_type', 'Unclassified'),
                'tourist': alert.user.username,
                'severity': severity,
                'status': details.get('case_status', alert.status),
                'date': alert.timestamp.strftime('%Y-%m-%d'),
                'time': alert.timestamp.strftime('%H:%M:%S'),
                'description': description[:100] + '...' if len(description) > 100 else description,
                'filing_officer': details.get('filing_officer', 'System'),
                'witnesses': len(details.get('witnesses', [])),
                'location': alert.location
            })
        
        return JsonResponse({
            'total': len(incidents),
            'incidents': incidents,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def get_audit_logs(request):
    """
    Get system audit logs - tracks all actions by authorities
    Returns: List of audit log entries with user actions
    """
    try:
        # Get recent alerts which serve as activity logs
        recent_activities = Alert.objects.select_related('user', 'assigned_to').order_by('-timestamp')[:100]
        
        audit_logs = []
        action_map = {
            'SOS': 'SOS Alert Created',
            'GeoFence': 'GeoFence Violation Detected',
            'Risk': 'Risk Zone Alert',
            'e-FIR': 'e-FIR Filed',
            'Incident': 'Incident Reported'
        }
        
        for activity in recent_activities:
            # Determine action type
            action = 'Alert Triggered'
            for key, value in action_map.items():
                if key in activity.alert_type:
                    action = value
                    break
            
            # Get additional user info if available
            details = activity.details or {}
            
            audit_logs.append({
                'timestamp': activity.timestamp.isoformat(),
                'time': activity.timestamp.strftime('%H:%M:%S'),
                'user': activity.user.username,
                'action': action,
                'resource': f"{activity.alert_type} #{activity.id}",
                'status': activity.status,
                'details': f"Alert by {activity.user.username} - {activity.alert_type}",
                'ip': '127.0.0.1'  # Would be captured from request in production
            })
        
        return JsonResponse({
            'total': len(audit_logs),
            'logs': audit_logs,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)



def get_risk_predictions(request):
    """
    API endpoint to fetch predictive risk zones from ML model
    Returns array of risk zones with risk scores and ML predictions
    """
    import requests
    
    risk_zones = []
    
    # Try to fetch from AI service
    try:
        ai_payload = {
            "centroid_lat": 22.5726,
            "centroid_lon": 88.3639,
            "threshold": 50
        }
        ai_response = requests.post(
            'http://localhost:8000/predict-risk-zones/',
            json=ai_payload,
            timeout=5
        )
        if ai_response.status_code == 200:
            ai_data = ai_response.json()
            # Transform AI service response format
            predicted_hotspots = ai_data.get('predicted_hotspots', [])
            
            for hotspot in predicted_hotspots:
                try:
                    # Map risk_level string to risk_score (0-100)
                    risk_level = hotspot.get('risk_level', 'Low').lower()
                    if risk_level == 'critical' or risk_level == 'very high':
                        risk_score = 95
                    elif risk_level == 'high':
                        risk_score = 80
                    elif risk_level == 'medium':
                        risk_score = 55
                    else:  # Low
                        risk_score = 30
                    
                    risk_zones.append({
                        'lat': float(hotspot.get('lat', 22.5726)),
                        'lon': float(hotspot.get('lon', 88.3639)),
                        'radius': 800,  # ML predicted hotspots get 800m radius
                        'risk_score': risk_score,
                        'reason': f"ML Predicted Hotspot - {hotspot.get('risk_level', 'Unknown')} Risk",
                        'timestamp': timezone.now().isoformat(),
                        'model_type': 'ML-DBSCAN'
                    })
                except Exception as inner_e:
                    logger.warning(f"Error processing AI hotspot: {inner_e}")
                    continue
            
            logger.info(f"Successfully fetched {len(predicted_hotspots)} ML predictions from AI service")
    except requests.exceptions.Timeout:
        logger.warning("AI service request timed out")
    except requests.exceptions.ConnectionError:
        logger.warning("Could not connect to AI service at localhost:8000")
    except Exception as e:
        logger.warning(f"Error fetching from AI service: {e}")
    
    # Fallback: Add alert-based risk zones to supplement ML predictions
    try:
        # Get recent alerts with high severity
        recent_alerts = Alert.objects.filter(
            timestamp__gte=timezone.now() - timedelta(hours=24)
        ).values('location', 'alert_type')
        
        # Convert alerts to risk zones
        alert_locations = {}
        for alert in recent_alerts:
            if alert['location']:
                try:
                    if isinstance(alert['location'], str):
                        loc = json.loads(alert['location'])
                    else:
                        loc = alert['location']
                    
                    key = f"{loc.get('lat', 0)}_{loc.get('lon', 0)}"
                    if key not in alert_locations:
                        alert_locations[key] = {
                            'lat': loc.get('lat', 22.5726),
                            'lon': loc.get('lon', 88.3639),
                            'count': 0,
                            'types': []
                        }
                    
                    alert_locations[key]['count'] += 1
                    if alert['alert_type'] not in alert_locations[key]['types']:
                        alert_locations[key]['types'].append(alert['alert_type'])
                except:
                    continue
        
        # Convert to risk zones with scores
        for loc_key, location_data in alert_locations.items():
            # Risk score based on alert count: more alerts = higher risk
            risk_score = min(100, 20 + (location_data['count'] * 10))
            
            risk_zones.append({
                'lat': location_data['lat'],
                'lon': location_data['lon'],
                'radius': 500 if risk_score < 60 else 1000,
                'risk_score': risk_score,
                'reason': f"{location_data['count']} alerts detected",
                'timestamp': timezone.now().isoformat(),
                'model_type': 'Alert-Based'
            })
        
        # Also add geozones as risk areas
        geozones = GeoZone.objects.all()
        for zone in geozones:
            try:
                # High risk geozones get higher scores
                if zone.zone_type and ('high' in zone.zone_type.lower()):
                    risk_score = 75
                elif zone.zone_type and ('medium' in zone.zone_type.lower()):
                    risk_score = 55
                else:
                    risk_score = 35
                
                risk_zones.append({
                    'lat': float(zone.center_lat),
                    'lon': float(zone.center_lon),
                    'radius': float(zone.radius_km) * 1000,
                    'risk_score': risk_score,
                    'reason': f"Geozone: {zone.zone_type}",
                    'timestamp': timezone.now().isoformat(),
                    'model_type': 'Geozone'
                })
            except:
                continue
        
        return JsonResponse({
            'status': 'success',
            'risk_zones': sorted(risk_zones, key=lambda x: x['risk_score'], reverse=True)
        })
    
    except Exception as e:
        logger.error(f"Error generating risk predictions: {e}")
        return JsonResponse({
            'status': 'error',
            'error': str(e),
            'risk_zones': []
        }, status=500)



def assign_help_to_tourist(request):
    """
    API endpoint to assign help/responders to a tourist in distress
    This endpoint finds nearby responders and dispatches them
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        tourist_id = data.get('tourist_id')
        help_type = data.get('help_type', 'rescue')
        priority = data.get('priority', 'high')
        notes = data.get('notes', '')
        
        tourist = CustomUser.objects.get(id=tourist_id, is_staff=False)
        
        # Get tourist's current location
        lat = 22.5726
        lon = 88.3639
        if tourist.location_history and len(tourist.location_history) > 0:
            last_loc = tourist.location_history[-1]
            if isinstance(last_loc, dict):
                lat = float(last_loc.get('lat', lat))
                lon = float(last_loc.get('lon', lon))
        
        # For now, assign to a default responder
        # In production, this would use geolocation to find nearest responders
        responder_names = ['Officer Sharma', 'Constable Kumar', 'Inspector Patel', 'Rescue Team Alpha']
        responder_phones = ['+91-9876543210', '+91-9876543211', '+91-9876543212', '+91-9876543213']
        responder_idx = tourist_id % len(responder_names)
        
        responder_name = responder_names[responder_idx]
        responder_phone = responder_phones[responder_idx]
        
        # Create an alert record for this assignment
        alert_data = {
            'help_type': help_type,
            'priority': priority,
            'assigned_responder': responder_name,
            'responder_phone': responder_phone,
            'notes': notes,
            'assignment_time': timezone.now().isoformat()
        }
        
        alert = Alert.objects.create(
            user=tourist,
            alert_type='Help Assignment',
            location={'lat': lat, 'lon': lon},
            details=alert_data,
            status='active',
            assigned_to=None  # Would be the responder user object in production
        )
        
        return JsonResponse({
            'status': 'success',
            'message': 'Help assigned successfully',
            'responder_name': responder_name,
            'responder_phone': responder_phone,
            'help_type': help_type,
            'priority': priority,
            'eta': '5-10 minutes'
        })
    
    except CustomUser.DoesNotExist:
        return JsonResponse({'error': 'Tourist not found'}, status=404)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        logger.error(f"Error assigning help: {e}")
        return JsonResponse({'error': str(e)}, status=500)