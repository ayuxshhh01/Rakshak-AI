from django.contrib import admin

# Register your models here.
from .models import *


admin.site.register(CustomUser)
admin.site.register(Alert)
admin.site.register(GeoZone)
admin.site.register(Itinerary)
admin.site.register(TrustedCircleMember)
admin.site.register(SafeRoute)
admin.site.register(CheckIn)
admin.site.register(AreaSafetyRating)
admin.site.register(EmergencyNumber)
admin.site.register(EmergencyPhrase)
admin.site.register(IncidentReport)
