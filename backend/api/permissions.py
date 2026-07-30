from rest_framework import permissions
from django.contrib.auth.models import Group

class IsStaffUser(permissions.BasePermission):
    """Permission to check if user is staff (authority portal access)"""
    message = "Only staff members can access this resource."
    
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_staff)


class IsIncidentCommander(permissions.BasePermission):
    """Permission for Incident Commanders - can manage all alerts"""
    message = "Only Incident Commanders can perform this action."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.groups.filter(name='Incident Commander').exists()


class IsFieldOfficer(permissions.BasePermission):
    """Permission for Field Response Officers - can view and update assigned alerts"""
    message = "Only Field Officers can perform this action."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.groups.filter(name='Field Officer').exists()


class IsAreaManager(permissions.BasePermission):
    """Permission for Area Managers - can manage zone-specific data"""
    message = "Only Area Managers can perform this action."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.groups.filter(name='Area Manager').exists()


class IsDataAnalyst(permissions.BasePermission):
    """Permission for Data Analysts - read-only access to analytics"""
    message = "Only Data Analysts can perform this action."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.groups.filter(name='Data Analyst').exists()


class IsAdminUser(permissions.BasePermission):
    """Permission for System Administrators - full access"""
    message = "Only administrators can perform this action."
    
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_superuser)


class IsTourist(permissions.BasePermission):
    """Permission to check if user is a regular tourist (not staff)"""
    message = "Only tourists can access this resource."
    
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and not request.user.is_staff)
