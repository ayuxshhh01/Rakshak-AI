from django.db import models
from django.contrib.auth.models import Group, Permission
from django.contrib.contenttypes.models import ContentType

class UserRole(models.Model):
    """Enhanced user role management with authority level"""
    
    ROLE_CHOICES = [
        ('super_admin', 'Super Administrator'),
        ('incident_commander', 'Incident Commander'),
        ('field_officer', 'Field Response Officer'),
        ('area_manager', 'Area Manager'),
        ('data_analyst', 'Data Analyst'),
        ('communication_officer', 'Communication Officer'),
        ('tourist', 'Tourist'),
    ]
    
    AUTHORITY_LEVEL = [
        (1, 'Lowest - Tourist'),
        (2, 'Data Analyst'),
        (3, 'Area Manager'),
        (4, 'Field Officer'),
        (5, 'Incident Commander'),
        (6, 'Super Admin - Highest'),
    ]
    
    user = models.OneToOneField('api.CustomUser', on_delete=models.CASCADE, related_name='role_profile')
    role = models.CharField(max_length=50, choices=ROLE_CHOICES, default='tourist')
    authority_level = models.IntegerField(choices=AUTHORITY_LEVEL, default=1)
    department = models.CharField(max_length=100, blank=True)  # e.g., Police, Tourism, Medical
    zone_assigned = models.ForeignKey('api.GeoZone', on_delete=models.SET_NULL, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "User Role"
        verbose_name_plural = "User Roles"
    
    def __str__(self):
        return f"{self.user.username} - {self.get_role_display()}"
    
    def has_permission(self, permission_string):
        """Check if user has specific permission"""
        return self.user.has_perm(permission_string)


class AuditLog(models.Model):
    """Track all authority actions for accountability"""
    
    ACTION_TYPES = [
        ('view', 'Viewed Data'),
        ('create', 'Created'),
        ('update', 'Updated'),
        ('delete', 'Deleted'),
        ('alert_assigned', 'Alert Assigned'),
        ('alert_resolved', 'Alert Resolved'),
        ('report_generated', 'Report Generated'),
        ('export', 'Data Exported'),
        ('login', 'Login'),
        ('logout', 'Logout'),
    ]
    
    user = models.ForeignKey('api.CustomUser', on_delete=models.CASCADE, related_name='audit_logs')
    action = models.CharField(max_length=50, choices=ACTION_TYPES)
    resource = models.CharField(max_length=200)  # What was affected (e.g., Alert #123, Tourist #456)
    description = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.user.username} - {self.action} - {self.timestamp}"


class ResponderAssignment(models.Model):
    """Track assignment of alerts to field responders"""
    
    STATUS_CHOICES = [
        ('unassigned', 'Unassigned'),
        ('assigned', 'Assigned - Pending'),
        ('acknowledged', 'Acknowledged'),
        ('en_route', 'En Route'),
        ('at_scene', 'At Scene'),
        ('resolved', 'Resolved'),
        ('escalated', 'Escalated'),
    ]
    
    alert = models.ForeignKey('api.Alert', on_delete=models.CASCADE, related_name='responder_assignments')
    responder = models.ForeignKey('api.CustomUser', on_delete=models.SET_NULL, null=True, blank=True, 
                                  related_name='assigned_alerts_new',
                                  limit_choices_to={'user_role_profile__role': 'field_officer'})
    commander = models.ForeignKey('api.CustomUser', on_delete=models.SET_NULL, null=True, blank=True,
                                  related_name='commanded_assignments',
                                  limit_choices_to={'user_role_profile__role': 'incident_commander'})
    assigned_at = models.DateTimeField(auto_now_add=True)
    acknowledged_at = models.DateTimeField(null=True, blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='unassigned')
    instructions = models.TextField(blank=True)  # Special instructions for responder
    notes = models.TextField(blank=True)  # Responder's on-scene notes
    eta_minutes = models.IntegerField(null=True, blank=True)  # Estimated time to arrive
    
    class Meta:
        ordering = ['-assigned_at']
    
    def __str__(self):
        return f"Alert #{self.alert.id} -> {self.responder.username if self.responder else 'Unassigned'}"


class IncidentReport(models.Model):
    """Comprehensive incident reporting system"""
    
    INCIDENT_SEVERITY = [
        ('low', 'Low Priority'),
        ('medium', 'Medium Priority'),
        ('high', 'High Priority'),
        ('critical', 'Critical'),
    ]
    
    INCIDENT_STATUS = [
        ('reported', 'Reported'),
        ('investigating', 'Under Investigation'),
        ('resolved', 'Resolved'),
        ('closed', 'Case Closed'),
    ]
    
    incident_id = models.CharField(max_length=50, unique=True)  # e.g., INC-2024-001
    tourist = models.ForeignKey('api.CustomUser', on_delete=models.CASCADE, related_name='incidents')
    incident_type = models.CharField(max_length=100)  # Theft, Assault, Lost, etc.
    severity = models.CharField(max_length=20, choices=INCIDENT_SEVERITY, default='medium')
    status = models.CharField(max_length=20, choices=INCIDENT_STATUS, default='reported')
    description = models.TextField()
    location = models.JSONField()  # {'lat': x, 'lon': y}
    witnesses = models.JSONField(default=list)  # List of witness names
    reported_by = models.ForeignKey('api.CustomUser', on_delete=models.SET_NULL, null=True, blank=True,
                                    related_name='reported_incidents')
    reported_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_notes = models.TextField(blank=True)
    attachments = models.JSONField(default=list)  # URLs to evidence/documents
    
    class Meta:
        ordering = ['-reported_at']
    
    def __str__(self):
        return f"{self.incident_id} - {self.incident_type}"


class AlertEscalation(models.Model):
    """Track alert escalation chain"""
    
    ESCALATION_LEVELS = [
        (1, 'Field Officer'),
        (2, 'Incident Commander'),
        (3, 'Superintendent'),
        (4, 'Commissioner'),
    ]
    
    alert = models.ForeignKey('api.Alert', on_delete=models.CASCADE, related_name='escalations')
    escalated_from = models.IntegerField(choices=ESCALATION_LEVELS)
    escalated_to = models.IntegerField(choices=ESCALATION_LEVELS)
    reason = models.TextField()
    escalated_by = models.ForeignKey('api.CustomUser', on_delete=models.SET_NULL, null=True, blank=True)
    escalated_at = models.DateTimeField(auto_now_add=True)
    resolved = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-escalated_at']
    
    def __str__(self):
        return f"Alert #{self.alert.id} escalated to level {self.escalated_to}"
