from api.models import CustomUser
from rest_framework.authtoken.models import Token

# Create or get test user
user, created = CustomUser.objects.get_or_create(username='safetytest')
user.set_password('safetytest123')
user.save()
print(f"User created/updated: {user.username}")

# Create token
token, token_created = Token.objects.get_or_create(user=user)
print(f"Token: {token.key}")
print(f"Ready for testing!")
