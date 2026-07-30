# in api/routing.py

from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    # This regular expression must exactly match the URL path.
    # The `^` means "starts with" and `$` means "ends with".
    re_path(r'^ws/alerts/$', consumers.AlertConsumer.as_asgi()),
]