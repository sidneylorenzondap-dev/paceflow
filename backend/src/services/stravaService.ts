import { TelemetrySamplePayload } from './telemetryService';
import { db, RunRecord } from './mockDb';
import crypto from 'crypto';

export const importLatestStravaRun = async (): Promise<any> => {
  const token = process.env.STRAVA_ACCESS_TOKEN || '';

  if (token === 'YOUR_MOCK_STRAVA_KEY_HERE') {
    // Generate a beautiful mock 5K run geojson with heat/fatigue data
    const coordinates = [];
    const heartRates = [];
    const cadences = [];
    const times = [];

    let lat = 37.7749;
    let lon = -122.4194;
    
    for (let i = 0; i < 300; i++) {
      lat += (Math.random() - 0.2) * 0.0005; // mostly moving north-ish
      lon += (Math.random() - 0.5) * 0.0005;
      coordinates.push([lon, lat]); // GeoJSON expects [lon, lat]
      
      // Heart rate spikes halfway through
      let hr = 140 + (i > 150 ? 20 : 0) + Math.random() * 5;
      heartRates.push(Math.round(hr));

      // Cadence drops near the end (fatigue)
      let cadence = 175 - (i > 250 ? 10 : 0) + Math.random() * 2;
      cadences.push(Math.round(cadence));

      times.push(Date.now() - (300 - i) * 1000);
    }

    const record: RunRecord = {
      id: crypto.randomUUID(),
      date: new Date().toISOString(),
      distanceMeters: 5000,
      durationSecs: 300,
      avgHeartRate: Math.round(heartRates.reduce((a, b) => a + b, 0) / heartRates.length),
      avgCadence: Math.round(cadences.reduce((a, b) => a + b, 0) / cadences.length),
      source: 'Strava'
    };
    db.saveRun(record);

    return {
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          geometry: {
            type: "LineString",
            coordinates
          },
          properties: {
            heartRates,
            cadences,
            times
          }
        }
      ]
    };
  } else {
    // Here we would implement the real Strava API fetch:
    // 1. GET https://www.strava.com/api/v3/athlete/activities?per_page=1
    // 2. GET https://www.strava.com/api/v3/activities/{id}/streams?keys=time,latlng,heartrate,cadence
    // 3. Transform to GeoJSON format above
    throw new Error('Real Strava fetch not fully implemented yet');
  }
};
