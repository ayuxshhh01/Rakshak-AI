# Production Settings for Firebase Deployment
# Copy this to backend/settings_production.py or add to settings.py for production

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# ⚠️ SECURITY: Change these in production
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'your-secret-key-here')
DEBUG = os.environ.get('DEBUG', 'False') == 'True'

# Firebase / Cloud Run settings
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost').split(',')
CSRF_TRUSTED_ORIGINS = [
    'https://*.run.app',
    'https://*.firebaseapp.com',
]

# CORS Settings
CORS_ALLOWED_ORIGINS = os.environ.get('CORS_ALLOWED_ORIGINS', 'http://localhost:3000').split(',')

# Database - Firestore (optional, keep SQLite for now)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Channel Layers - Use simple in-memory or configure Redis
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels.layers.InMemoryChannelLayer'
    }
}

# Cache
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }
}

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Media files (use Cloud Storage in production)
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}

# Security settings
SECURE_SSL_REDIRECT = not DEBUG
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
X_FRAME_OPTIONS = 'DENY'

# Firebase config (optional)
FIREBASE_PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID')
FIREBASE_API_KEY = os.environ.get('FIREBASE_API_KEY')
