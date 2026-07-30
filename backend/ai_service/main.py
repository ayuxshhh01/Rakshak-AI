import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
# --- 1. Add this import for CORS ---
from fastapi.middleware.cors import CORSMiddleware

# --- Initialize the FastAPI Application ---
app = FastAPI(
    title="Smart Tourist Safety AI Service",
    description="Provides predictions for risk zones and other anomalies.",
    version="1.0.0",
)

# --- 2. Add the CORS Middleware ---
# This allows your web portal (running on a different address) to communicate with this AI service.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)


# --- Load the Trained Model and Data ---
try:
    risk_model = joblib.load("risk_zone_model.joblib")
    incident_data = pd.read_csv("clean_incident_data.csv")
    print("AI model and incident data loaded successfully.")
except FileNotFoundError:
    risk_model = None
    incident_data = None
    print("Warning: Model or data file not found. API will run with mock data.")

# --- Define Data Models for API Requests ---
class GpsPoint(BaseModel):
    lat: float
    lon: float

# --- Pre-calculate Cluster Centers ---
cluster_centers = []
if risk_model and incident_data is not None:
    incident_data.dropna(subset=['latitude', 'longitude'], inplace=True)
    labels = risk_model.labels_
    unique_labels = set(labels)
    coords = incident_data[['latitude', 'longitude']].values
    
    for label in unique_labels:
        if label != -1:
            cluster_points = coords[labels == label]
            center = cluster_points.mean(axis=0)
            cluster_centers.append({"lat": center[0], "lon": center[1], "risk_level": "High"})

# --- Define the API Endpoints ---
@app.get("/")
def read_root():
    return {"message": "AI Service is running. Navigate to /docs for the API interface."}

@app.post("/predict-risk-zones")
def predict_risk_zones():
    """
    Returns the pre-calculated centers of all high-risk incident zones.
    """
    if not cluster_centers:
         return {"warning": "No clusters found in the model or model not loaded.", "predicted_hotspots": []}
         
    print(f"Returning {len(cluster_centers)} pre-calculated high-risk zones.")
    return {"predicted_hotspots": cluster_centers}