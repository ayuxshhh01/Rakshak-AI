#!/usr/bin/env python3
"""
Simple API test script to verify all safety features are working
"""
import requests
import json

BASE_URL = "http://localhost:8000/api"

# Test data
USERNAME = "admin"
PASSWORD = "admin123"

def login():
    """Test login endpoint"""
    print("\n=== Testing Login ===")
    url = f"{BASE_URL}/login/"
    data = {"username": USERNAME, "password": PASSWORD}
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        
        if response.status_code == 200:
            token = response.json().get('token')
            return token
        else:
            print("Login failed, trying to register first...")
            return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def register():
    """Test register endpoint"""
    print("\n=== Testing Register ===")
    url = f"{BASE_URL}/register/"
    data = {
        "username": USERNAME,
        "password": PASSWORD,
        "phone_number": "9876543210",
        "emergency_contact": "9876543211"
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

def test_endpoints(token):
    """Test all safety feature endpoints"""
    headers = {"Authorization": f"Token {token}"}
    
    endpoints = [
        ("GET", "/trusted-circle/", None),
        ("GET", "/shared-locations/", None),
        ("GET", "/safe-routes/", None),
        ("GET", "/check-ins/", None),
        ("GET", "/area-safety/", None),
        ("GET", "/emergency-numbers/", None),
        ("GET", "/emergency-phrases/?language=English", None),
        ("GET", "/incident-reports/", None),
    ]
    
    for method, endpoint, data in endpoints:
        print(f"\n=== Testing {method} {endpoint} ===")
        url = f"{BASE_URL}{endpoint}"
        
        try:
            if method == "GET":
                response = requests.get(url, headers=headers)
            elif method == "POST":
                response = requests.post(url, json=data, headers=headers)
            
            print(f"Status: {response.status_code}")
            if response.status_code < 400:
                print(f"✓ Endpoint working")
                # Print first 200 chars of response
                resp_text = str(response.json())[:200]
                print(f"Response preview: {resp_text}")
            else:
                print(f"✗ Error: {response.text[:200]}")
        except Exception as e:
            print(f"✗ Exception: {e}")

def test_create_endpoints(token):
    """Test POST endpoints for creating resources"""
    headers = {"Authorization": f"Token {token}"}
    
    print("\n\n=== Testing CREATE Endpoints ===")
    
    # Test add trusted circle member
    print("\n--- Add Trusted Circle Member ---")
    url = f"{BASE_URL}/trusted-circle/"
    data = {
        "name": "Mom",
        "phone_number": "+919876543212",
        "relationship": "Family",
        "can_see_location": True,
        "can_see_status": True
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"Status: {response.status_code}")
        if response.status_code in [200, 201]:
            print(f"✓ Successfully created: {response.json()}")
        else:
            print(f"✗ Error: {response.text[:200]}")
    except Exception as e:
        print(f"✗ Exception: {e}")
    
    # Test create check-in
    print("\n--- Create Check-In ---")
    url = f"{BASE_URL}/check-ins/"
    data = {
        "lat": 28.7041,
        "lon": 77.1025,
        "location_name": "India Gate",
        "status": "Safe",
        "note": "Everything is good",
        "visibility": "Trusted Circle"
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"Status: {response.status_code}")
        if response.status_code in [200, 201]:
            print(f"✓ Successfully created: {response.json()}")
        else:
            print(f"✗ Error: {response.text[:200]}")
    except Exception as e:
        print(f"✗ Exception: {e}")
    
    # Test create incident report
    print("\n--- Create Incident Report ---")
    url = f"{BASE_URL}/incident-reports/"
    data = {
        "lat": 28.7041,
        "lon": 77.1025,
        "location_name": "India Gate",
        "incident_type": "Theft",
        "description": "Someone tried to pickpocket me",
        "severity": "Medium"
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"Status: {response.status_code}")
        if response.status_code in [200, 201]:
            print(f"✓ Successfully created: {response.json()}")
        else:
            print(f"✗ Error: {response.text[:200]}")
    except Exception as e:
        print(f"✗ Exception: {e}")

def main():
    print("=" * 50)
    print("API Safety Features Test")
    print("=" * 50)
    
    # Try login first
    token = login()
    
    if not token:
        print("\nAttempting to register new user...")
        register()
        token = login()
    
    if token:
        print(f"\n✓ Successfully logged in with token: {token[:20]}...")
        test_endpoints(token)
        test_create_endpoints(token)
    else:
        print("\n✗ Could not obtain authentication token")

if __name__ == "__main__":
    main()
