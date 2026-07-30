# in api/consumers.py

import json
from channels.generic.websocket import AsyncWebsocketConsumer

class AlertConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_group_name = 'alerts_group'

        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
        print("WebSocket connection established.")

    async def disconnect(self, close_code):
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        print("WebSocket connection closed.")

    # This method is called when we send a message to the group from our Django view.
    async def send_alert(self, event):
        alert_data = event['alert']
        # Send message to WebSocket
        await self.send(text_data=json.dumps(alert_data))
        print(f"Sent alert data to WebSocket: {alert_data}")