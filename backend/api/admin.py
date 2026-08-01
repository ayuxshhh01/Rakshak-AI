from django.contrib import admin

# Register your models here.
from .models import *
from .authority_models import UserRole, AuditLog, ResponderAssignment, AlertEscalation


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


@admin.register(UserRole)
class UserRoleAdmin(admin.ModelAdmin):
	list_display = ('user', 'role', 'authority_level', 'department', 'zone_assigned', 'is_active', 'created_at')
	list_filter = ('role', 'authority_level', 'department', 'is_active')
	search_fields = ('user__username', 'user__email', 'department')
	raw_id_fields = ('user', 'zone_assigned')


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
	list_display = ('user', 'action', 'resource', 'ip_address', 'timestamp')
	list_filter = ('action', 'user')
	search_fields = ('user__username', 'resource', 'description')
	readonly_fields = ('timestamp',)


@admin.register(ResponderAssignment)
class ResponderAssignmentAdmin(admin.ModelAdmin):
	list_display = ('alert', 'responder', 'commander', 'status', 'assigned_at', 'acknowledged_at', 'resolved_at')
	list_filter = ('status',)
	search_fields = ('alert__id', 'responder__username', 'commander__username')
	raw_id_fields = ('alert', 'responder', 'commander')


@admin.register(AlertEscalation)
class AlertEscalationAdmin(admin.ModelAdmin):
	list_display = ('alert', 'escalated_from', 'escalated_to', 'escalated_by', 'escalated_at', 'resolved')
	list_filter = ('escalated_to', 'resolved')
	search_fields = ('alert__id', 'escalated_by__username')
	raw_id_fields = ('alert', 'escalated_by')
