# Tourist Safety App - Flow Diagrams

This folder contains all the system architecture and flow diagrams for the Tourist Safety Application project.

## Diagrams Included

### 1. System Architecture (`1_system_architecture.md`)
Complete overview of the entire system showing:
- Flutter Mobile App with 4 main screens
- 10 Safety Features
- Django REST API backends
- Data Services layer (Google Places, Crime Data, etc.)
- Database structure
- Information flow between all components

### 2. Feature Flows (`2_feature_flows.md`)
Detailed step-by-step flows for specific features:
- **SOS Alert Flow**: How panic button/voice SOS works
- **Medical Facilities Flow**: Finding nearby hospitals
- **Area Safety Flow**: Getting real-time safety ratings

### 3. Technology Stack (`3_technology_stack.md`)
Shows all technologies used:
- **Frontend**: Flutter, BLoC, Geolocator, Speech-to-text
- **Backend**: Django, DRF, Celery, Channels
- **Services**: Google APIs, Twilio, SendGrid
- **Database**: SQLite, PostgreSQL, Redis

### 4. User Flow & Sequence (`4_user_flow_sequence.md`)
Detailed sequence diagram showing:
- User authentication flow
- Login/token generation
- Medical facilities request flow
- SOS alert trigger and notification flow
- Step-by-step interactions between components

## How to View

These diagrams are in Mermaid format. You can:

1. **View in GitHub**: If in a GitHub repository, diagrams render automatically
2. **View in VS Code**: Install Mermaid extension for VS Code
3. **View Online**: Use [Mermaid Live Editor](https://mermaid.live/)
4. **Export as Image**: Copy the code to mermaid.live and export as PNG/SVG

## Features Covered

- ✅ Authentication & Authorization
- ✅ Medical Facilities (Real hospitals via Google Places)
- ✅ Emergency Services (Police/Fire/Ambulance)
- ✅ Area Safety Ratings (Crime data integration)
- ✅ SOS/Panic Button
- ✅ Voice SOS (Keyword detection)
- ✅ Trusted Circle (Emergency contacts)
- ✅ Check-Ins (Proof of life)
- ✅ Incident Reports (Crowdsourced data)
- ✅ Emergency Numbers (Government verified)
- ✅ Safe Routes (Crime-weighted navigation)
- ✅ Real-time Location Tracking
- ✅ Multi-channel Notifications (Email, SMS, Push)

## Color Scheme

All diagrams use:
- **Background**: White (#ffffff)
- **Text**: Black (#000000)
- **Borders**: Black (#000000)

Perfect for printing and presentations!
