from django.core.management.base import BaseCommand
from api.models import SafeRoute, CheckIn, CustomUser

class Command(BaseCommand):
    help = 'Seed safe routes and check-ins for all existing users'

    def handle(self, *args, **options):
        users = CustomUser.objects.all()
        
        for user in users:
            # Check if user already has routes
            if SafeRoute.objects.filter(user=user).exists():
                continue
            
            # Create sample routes
            safe_routes = [
                SafeRoute(
                    user=user,
                    start_location={'lat': 28.7041, 'lon': 77.1025},
                    end_location={'lat': 28.6129, 'lon': 77.2295},
                    route_name='Home to Office - Safe Route 1',
                    waypoints=[
                        {'lat': 28.6500, 'lon': 77.1650},
                        {'lat': 28.6200, 'lon': 77.1950},
                    ],
                    danger_zones=[],
                    safety_score=92,
                    distance_km=12.5,
                    estimated_time_minutes=32,
                    is_saved=True,
                ),
                SafeRoute(
                    user=user,
                    start_location={'lat': 28.7041, 'lon': 77.1025},
                    end_location={'lat': 28.4595, 'lon': 77.0266},
                    route_name='Downtown - Safe Route 2',
                    waypoints=[
                        {'lat': 28.6750, 'lon': 77.0750},
                        {'lat': 28.5500, 'lon': 77.0500},
                    ],
                    danger_zones=[],
                    safety_score=85,
                    distance_km=18.3,
                    estimated_time_minutes=45,
                    is_saved=True,
                ),
            ]
            SafeRoute.objects.bulk_create(safe_routes)
            
            # Create sample check-ins
            check_ins = [
                CheckIn(
                    user=user,
                    location={'lat': 28.7041, 'lon': 77.1025},
                    location_name='New Delhi',
                    status='Safe',
                    note='All good, at home',
                    visibility='Trusted Circle',
                ),
                CheckIn(
                    user=user,
                    location={'lat': 28.6129, 'lon': 77.2295},
                    location_name='Gurgaon',
                    status='Safe',
                    note='At office, in a secure building',
                    visibility='Trusted Circle',
                ),
            ]
            CheckIn.objects.bulk_create(check_ins)
            
            self.stdout.write(f'✓ Created sample data for user: {user.username}')
        
        self.stdout.write(self.style.SUCCESS('✓ All user data seeded successfully!'))
