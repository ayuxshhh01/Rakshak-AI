from django.urls import path
from django.shortcuts import render
from .views import *


urlpatterns = [
    # Dashboard
    path('', dashboard_view, name='dashboard'),
    
    # API Endpoints - Core
    path('api/tourists/live/', get_live_tourists, name='get_live_tourists'),
    path('api/tourist-profile/<int:tourist_id>/', get_tourist_profile, name='get_tourist_profile'),
    path('api/location-history/<int:tourist_id>/', get_location_history, name='get_location_history'),
    
    # API Endpoints - Alerts
    path('api/alert-history/', get_alert_history, name='get_alert_history'),
    path('api/alert-details/<int:alert_id>/', get_alert_details, name='get_alert_details'),
    path('api/alerts/<int:alert_id>/update-status/', update_alert_status, name='update_alert_status'),
    
    # API Endpoints - Statistics & Analytics
    path('api/activity-stats/', get_activity_stats, name='get_activity_stats'),
    path('api/audit-logs/', get_audit_logs, name='get_audit_logs'),
    path('api/risk-predictions/', get_risk_predictions, name='get_risk_predictions'),
    
    # API Endpoints - Operations
    path('api/efir/file/', file_efir, name='file_efir'),
    path('api/assign-help/', assign_help_to_tourist, name='assign_help'),
]