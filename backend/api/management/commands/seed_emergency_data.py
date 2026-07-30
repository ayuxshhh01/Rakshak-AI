from django.core.management.base import BaseCommand
from api.models import EmergencyNumber, EmergencyPhrase, AreaSafetyRating, SafeRoute, CheckIn, CustomUser

class Command(BaseCommand):
    help = 'Seed database with emergency numbers, phrases, safe routes, and check-ins'

    def handle(self, *args, **options):
        # Clear existing data
        EmergencyNumber.objects.all().delete()
        EmergencyPhrase.objects.all().delete()
        AreaSafetyRating.objects.all().delete()
        SafeRoute.objects.all().delete()
        CheckIn.objects.all().delete()
        
        # Get or create a demo user
        demo_user, created = CustomUser.objects.get_or_create(
            username='demo_user',
            defaults={'email': 'demo@example.com', 'first_name': 'Demo', 'last_name': 'User', 'phone_number': '9876543210', 'emergency_contact': '9999999999'}
        )
        if created:
            demo_user.set_password('demo123')
            demo_user.save()
            self.stdout.write(self.style.SUCCESS('✓ Created demo user (demo_user:demo123)'))

        # Emergency Numbers - India
        emergency_numbers = [
            # Police
            EmergencyNumber(country='India', city='General', service_type='Police', service_name='Police Emergency', phone_number='100', language='English'),
            # Ambulance/Medical
            EmergencyNumber(country='India', city='General', service_type='Ambulance', service_name='Medical Emergency', phone_number='102', language='English'),
            # Fire
            EmergencyNumber(country='India', city='General', service_type='Fire', service_name='Fire Department', phone_number='101', language='English'),
            # Tourist Police (India specific)
            EmergencyNumber(country='India', city='General', service_type='Tourist Police', service_name='Tourist Police Helpline', phone_number='1363', language='English'),
            # US Embassy
            EmergencyNumber(country='India', city='Delhi', service_type='Embassy', service_name='US Embassy', phone_number='+91-11-2419-8000', description='US Embassy New Delhi', language='English'),
            # Additional services
            EmergencyNumber(country='India', city='General', service_type='Hospital', service_name='AIIMS Delhi', phone_number='011-2659-0500', description='All India Institute of Medical Sciences', language='English'),
            EmergencyNumber(country='India', city='General', service_type='Police', service_name='Women Helpline', phone_number='1091', description='24/7 Support for Women', language='English'),
            EmergencyNumber(country='India', city='General', service_type='Other', service_name='Poison Control', phone_number='1800-11-1700', language='English'),
        ]
        EmergencyNumber.objects.bulk_create(emergency_numbers)
        self.stdout.write(self.style.SUCCESS('✓ Added 8 emergency numbers'))

        # Emergency Phrases - Multiple Languages
        emergency_phrases = [
            # English
            EmergencyPhrase(language='English', phrase_type='Help', english_text='Help!', local_text='Help!', pronunciation='Help'),
            EmergencyPhrase(language='English', phrase_type='Police', english_text='Call the police', local_text='Call the police', pronunciation='Call the police'),
            EmergencyPhrase(language='English', phrase_type='Hospital', english_text='Take me to hospital', local_text='Take me to hospital', pronunciation='Take me to hospital'),
            EmergencyPhrase(language='English', phrase_type='Danger', english_text='I am in danger', local_text='I am in danger', pronunciation='I am in danger'),
            EmergencyPhrase(language='English', phrase_type='Safe', english_text='I am safe', local_text='I am safe', pronunciation='I am safe'),
            EmergencyPhrase(language='English', phrase_type='Address', english_text='What is your address?', local_text='What is your address?', pronunciation='What is your address'),
            
            # Hindi
            EmergencyPhrase(language='Hindi', phrase_type='Help', english_text='Help!', local_text='मदद!', pronunciation='Madad!'),
            EmergencyPhrase(language='Hindi', phrase_type='Police', english_text='Call the police', local_text='पुलिस को कॉल करें', pronunciation='Police ko call karen'),
            EmergencyPhrase(language='Hindi', phrase_type='Hospital', english_text='Take me to hospital', local_text='मुझे अस्पताल ले जाओ', pronunciation='Mujhe aspatal le jao'),
            EmergencyPhrase(language='Hindi', phrase_type='Danger', english_text='I am in danger', local_text='मैं खतरे में हूँ', pronunciation='Main khtre mein hun'),
            EmergencyPhrase(language='Hindi', phrase_type='Safe', english_text='I am safe', local_text='मैं सुरक्षित हूँ', pronunciation='Main surakshit hun'),
            EmergencyPhrase(language='Hindi', phrase_type='Water', english_text='Water please', local_text='पानी प्रदान करें', pronunciation='Pani pradan karen'),
            
            # Spanish
            EmergencyPhrase(language='Spanish', phrase_type='Help', english_text='Help!', local_text='¡Ayuda!', pronunciation='Ayuda'),
            EmergencyPhrase(language='Spanish', phrase_type='Police', english_text='Call the police', local_text='Llamar a la policía', pronunciation='Llamar a la policia'),
            EmergencyPhrase(language='Spanish', phrase_type='Hospital', english_text='Take me to hospital', local_text='Llévame al hospital', pronunciation='Llevame al hospital'),
            EmergencyPhrase(language='Spanish', phrase_type='Danger', english_text='I am in danger', local_text='Estoy en peligro', pronunciation='Estoy en peligro'),
            
            # French
            EmergencyPhrase(language='French', phrase_type='Help', english_text='Help!', local_text='Au secours!', pronunciation='Au secours'),
            EmergencyPhrase(language='French', phrase_type='Police', english_text='Call the police', local_text='Appeler la police', pronunciation='Appeler la police'),
            EmergencyPhrase(language='French', phrase_type='Hospital', english_text='Take me to hospital', local_text='Menez-moi à l\'hôpital', pronunciation='Menez-moi a lhopital'),
        ]
        EmergencyPhrase.objects.bulk_create(emergency_phrases)
        self.stdout.write(self.style.SUCCESS('✓ Added 20 emergency phrases'))

        # Area Safety Ratings - Major Indian Cities
        safety_ratings = [
            AreaSafetyRating(
                location_name='New Delhi',
                latitude=28.7041,
                longitude=77.1025,
                overall_rating=7.2,
                crime_rate=6.5,
                theft_incidents=45,
                violent_incidents=12,
                safe_hours={'start': '06:00', 'end': '22:00'},
                safe_areas='Central Delhi, Diplomatic Enclave, South Delhi',
                risky_areas='Certain areas of North Delhi late at night',
                user_reports_count=23,
            ),
            AreaSafetyRating(
                location_name='Mumbai',
                latitude=19.0760,
                longitude=72.8777,
                overall_rating=7.5,
                crime_rate=6.0,
                theft_incidents=32,
                violent_incidents=8,
                safe_hours={'start': '06:00', 'end': '23:00'},
                safe_areas='Bandra, Andheri, South Mumbai',
                risky_areas='Certain slum areas at night',
                user_reports_count=18,
            ),
            AreaSafetyRating(
                location_name='Bangalore',
                latitude=12.9716,
                longitude=77.5946,
                overall_rating=8.1,
                crime_rate=4.5,
                theft_incidents=18,
                violent_incidents=3,
                safe_hours={'start': '05:30', 'end': '23:30'},
                safe_areas='Indiranagar, Koramangala, Whitefield',
                risky_areas='Very safe overall',
                user_reports_count=8,
            ),
            AreaSafetyRating(
                location_name='Goa',
                latitude=15.2993,
                longitude=73.8243,
                overall_rating=8.3,
                crime_rate=3.8,
                theft_incidents=12,
                violent_incidents=2,
                safe_hours={'start': '06:00', 'end': '23:00'},
                safe_areas='Tourist beaches and resorts',
                risky_areas='Some remote areas late at night',
                user_reports_count=5,
            ),
            AreaSafetyRating(
                location_name='Jaipur',
                latitude=26.9124,
                longitude=75.7873,
                overall_rating=7.0,
                crime_rate=6.8,
                theft_incidents=52,
                violent_incidents=15,
                safe_hours={'start': '06:00', 'end': '21:00'},
                safe_areas='City Palace area, Tourist zones',
                risky_areas='Some Old City areas at night',
                user_reports_count=20,
            ),
        ]
        AreaSafetyRating.objects.bulk_create(safety_ratings)
        self.stdout.write(self.style.SUCCESS('✓ Added 5 area safety ratings'))

        # Safe Routes - Sample routes for demo
        safe_routes = [
            SafeRoute(
                user=demo_user,
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
                user=demo_user,
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
            SafeRoute(
                user=demo_user,
                start_location={'lat': 28.6129, 'lon': 77.2295},
                end_location={'lat': 28.5244, 'lon': 77.1855},
                route_name='Restaurant - Safe Route 3',
                waypoints=[
                    {'lat': 28.5750, 'lon': 77.2100},
                    {'lat': 28.5400, 'lon': 77.1950},
                ],
                danger_zones=[],
                safety_score=88,
                distance_km=8.7,
                estimated_time_minutes=22,
                is_saved=True,
            ),
        ]
        SafeRoute.objects.bulk_create(safe_routes)
        self.stdout.write(self.style.SUCCESS('✓ Added 3 safe routes'))

        # Check-Ins - Sample check-in data
        check_ins = [
            CheckIn(
                user=demo_user,
                location={'lat': 28.7041, 'lon': 77.1025},
                location_name='New Delhi',
                status='Safe',
                note='All good, at home',
                visibility='Trusted Circle',
            ),
            CheckIn(
                user=demo_user,
                location={'lat': 28.6129, 'lon': 77.2295},
                location_name='Gurgaon',
                status='Safe',
                note='At office, in a secure building',
                visibility='Trusted Circle',
            ),
            CheckIn(
                user=demo_user,
                location={'lat': 28.5244, 'lon': 77.1855},
                location_name='South Delhi',
                status='Moderate Risk',
                note='Out shopping, crowded place',
                visibility='Trusted Circle',
            ),
        ]
        CheckIn.objects.bulk_create(check_ins)
        self.stdout.write(self.style.SUCCESS('✓ Added 3 check-ins'))

        self.stdout.write(self.style.SUCCESS(self.style.SUCCESS('✓ All seed data loaded successfully!')))

