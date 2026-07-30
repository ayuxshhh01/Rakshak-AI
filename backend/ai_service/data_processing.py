import pandas as pd
from geopy.geocoders import Nominatim
from geopy.extra.rate_limiter import RateLimiter
import time

def process_real_data(input_csv="real_crime_data.csv"):
    """
    Loads, cleans, and processes a real government dataset for all of India
    to prepare it for model training.
    """
    print("Starting processing of real government data for ALL of India...")


    try:
        df = pd.read_csv(input_csv, encoding='unicode_escape')
    except FileNotFoundError:
        print(f"Error: The file '{input_csv}' was not found. Please place it in the 'ai_service' folder.")
        return


    print("Cleaning and preparing data...")
    df = df.rename(columns={'STATE/UT': 'State', 'DISTRICT': 'District', 'YEAR': 'Year'})
    
 
    df_filtered = df.copy()
    

    df_filtered['full_location'] = df_filtered['District'] + ', ' + df_filtered['State']

    print("Geocoding district names... This will take a while for the full dataset.")
    geolocator = Nominatim(user_agent="tourist_safety_app")
    geocode = RateLimiter(geolocator.geocode, min_delay_seconds=1)
    location_cache = {}
    
    def get_coords(location_str):
        if location_str in location_cache:
            return location_cache[location_str]
        try:
            location = geocode(location_str)
            if location:
                location_cache[location_str] = (location.latitude, location.longitude)
                print(f"  Successfully geocoded: {location_str} -> ({location.latitude}, {location.longitude})")
                return (location.latitude, location.longitude)
        except Exception as e:
            print(f"  Error geocoding {location_str}: {e}")
        return (None, None)

   
    df_filtered['coords'] = df_filtered['full_location'].apply(get_coords)
    
  
    df_filtered.dropna(subset=['coords'], inplace=True)
    df_filtered[['latitude', 'longitude']] = pd.DataFrame(df_filtered['coords'].tolist(), index=df_filtered.index)
    df_filtered['timestamp'] = pd.to_datetime(df_filtered['Year'], format='%Y')
    df_filtered['event_type'] = 'crime'

    final_df = df_filtered[['timestamp', 'latitude', 'longitude', 'event_type']]
    final_df.to_csv("clean_incident_data.csv", index=False)

    print(f"\nProcessing complete. A new pan-India dataset with {len(final_df)} records has been created.")
    print("\nSample of the new dataset:")
    print(final_df.head())


if __name__ == "__main__":
   
    process_real_data(input_csv="District-wise-cases-reported-under-IPC-and-SLL-2021.csv")



