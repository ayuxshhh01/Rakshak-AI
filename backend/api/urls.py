from django.urls import path
from .views import (
    RegisterView, 
    LoginView,
    UpdateLocationView, 
    PanicAlertView, 
    DashboardDataView,
    GeoZoneView,
    ItineraryGeneratorView,
    voice_alert_twiml,
    AlertActionView,
    TouristJourneyView,
    PredictRiskZonesView,
    # New views for 7 features
    TrustedCircleView,
    TrustedCircleDetailView,
    SharedLocationView,
    SafeRouteView,
    SafeRouteDetailView,
    CheckInView,
    PublicCheckInsView,
    AreaSafetyRatingView,
    EmergencyNumberView,
    EmergencyPhraseView,
    IncidentReportView,
    IncidentReportDetailView,
    IncidentReportLikeView,
    # Real-time data views
    MedicalFacilitiesView,
    EmergencyServicesView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    
    path('location/update/', UpdateLocationView.as_view(), name='update-location'),
    path('alerts/panic/', PanicAlertView.as_view(), name='panic-alert'),
    path('dashboard/', DashboardDataView.as_view(), name='dashboard-data'),
    path('geozones/', GeoZoneView.as_view(), name='geozones'),
    path('itinerary/generate/', ItineraryGeneratorView.as_view(), name='itinerary-generate'),
    path('voice-alert/<int:alert_id>/', voice_alert_twiml, name='voice-alert-twiml'),
    path('alerts/<int:alert_id>/action/', AlertActionView.as_view(), name='alert-action'),
    path('tourists/<int:user_id>/journey/', TouristJourneyView.as_view(), name='tourist-journey'),
    path('predict-risk-zones/', PredictRiskZonesView.as_view(), name='predict-risk-zones'),
    
    # ========= NEW URLs FOR 7 FEATURES =========
    
    # 1. TRUSTED CIRCLE
    path('trusted-circle/', TrustedCircleView.as_view(), name='trusted-circle-list'),
    path('trusted-circle/<int:pk>/', TrustedCircleDetailView.as_view(), name='trusted-circle-detail'),
    path('shared-locations/', SharedLocationView.as_view(), name='shared-locations'),
    
    # 2. SAFE ROUTE
    path('safe-routes/', SafeRouteView.as_view(), name='safe-routes-list'),
    path('safe-routes/<int:pk>/', SafeRouteDetailView.as_view(), name='safe-routes-detail'),
    
    # 3. CHECK-IN
    path('check-ins/', CheckInView.as_view(), name='checkin-list'),
    path('check-ins/public/', PublicCheckInsView.as_view(), name='checkin-public'),
    
    # 4. AREA SAFETY RATING
    path('area-safety/', AreaSafetyRatingView.as_view(), name='area-safety'),
    
    # 5. EMERGENCY NUMBER
    path('emergency-numbers/', EmergencyNumberView.as_view(), name='emergency-numbers'),
    
    # 6. EMERGENCY PHRASE
    path('emergency-phrases/', EmergencyPhraseView.as_view(), name='emergency-phrases'),
    
    # 7. INCIDENT REPORT
    path('incident-reports/', IncidentReportView.as_view(), name='incident-reports-list'),
    path('incident-reports/<int:pk>/', IncidentReportDetailView.as_view(), name='incident-reports-detail'),
    path('incident-reports/<int:report_id>/like/', IncidentReportLikeView.as_view(), name='incident-like'),
    
    # ========= REAL-TIME DATA ENDPOINTS (Google Places API + Crime Data) =========
    # These provide REAL data for tourist safety, not hardcoded/seeded data
    
    # Medical Facilities - Real-time from Google Places API
    path('medical-facilities/', MedicalFacilitiesView.as_view(), name='medical-facilities'),
    
    # Emergency Services - Real-time from Google Places API
    path('emergency-services/', EmergencyServicesView.as_view(), name='emergency-services'),
]