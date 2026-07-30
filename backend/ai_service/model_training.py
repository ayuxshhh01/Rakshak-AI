import pandas as pd
from sklearn.cluster import DBSCAN
import numpy as np
import joblib

def train_risk_zone_model():
    """
    Trains a DBSCAN model to find geographical hotspots of incidents and saves the
    trained model to a file for later use by the API.
    """
    print("Starting model training...")

    # --- Step 1: Load the clean, geocoded data from Phase 1 ---
    try:
        df = pd.read_csv("clean_incident_data.csv")
    except FileNotFoundError:
        print("Error: clean_incident_data.csv not found. Please run the data_processing.py script first.")
        return
    
    # Drop any rows that might have failed geocoding, just in case.
    df.dropna(subset=['latitude', 'longitude'], inplace=True)
    print(f"Training model on {len(df)} valid records...")

    # --- Step 2: Prepare data for DBSCAN ---
    # We only need the latitude and longitude columns for clustering.
    coords = df[['latitude', 'longitude']].values
    
    # DBSCAN works with real-world distances. We need to define our clustering radius
    # (epsilon) in terms of radians, as the haversine metric expects.
    kms_per_radian = 6371.0088
    # Let's define a hotspot as any area where incidents occur within a 1km radius.
    epsilon = 1 / kms_per_radian 

    # --- Step 3: Train the DBSCAN model ---
    # We are looking for clusters of at least 3 incidents to be considered a hotspot.
    db = DBSCAN(
        eps=epsilon, 
        min_samples=3, 
        algorithm='ball_tree', 
        metric='haversine'
    ).fit(np.radians(coords)) # Convert coordinates to radians for the haversine metric
    
    # The `labels_` attribute tells us which cluster each point belongs to.
    # A label of -1 means it's a noisy point (not part of any significant cluster).
    cluster_labels = db.labels_
    num_clusters = len(set(cluster_labels)) - (1 if -1 in cluster_labels else 0)
    
    print(f'Model training complete. Found {num_clusters} significant high-risk clusters.')

    # --- Step 4: Save the trained model to a file ---
    # We save the model using joblib. Our API will load this file to make live predictions.
    joblib.dump(db, 'risk_zone_model.joblib')
    print("Trained model saved to 'risk_zone_model.joblib'")

    # --- Optional: Display the centers of the found clusters ---
    if num_clusters > 0:
        print("\nIdentified High-Risk Zone Centers (latitude, longitude):")
        # Find all unique cluster labels (ignoring -1 for noise)
        unique_labels = set(cluster_labels)
        unique_labels.discard(-1)
        
        for label in unique_labels:
            # Get all the points belonging to the current cluster
            cluster_points = coords[cluster_labels == label]
            # Calculate the center of the cluster by averaging the coordinates
            center = cluster_points.mean(axis=0)
            print(f"  - Cluster {label}: ({center[0]:.4f}, {center[1]:.4f})")

if __name__ == "__main__":
    train_risk_zone_model()