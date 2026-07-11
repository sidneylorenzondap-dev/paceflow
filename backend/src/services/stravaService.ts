import { TelemetrySamplePayload } from './telemetryService';
import { prisma } from '../db';
import crypto from 'crypto';

export const importLatestStravaRun = async (): Promise<any> => {
  const token = process.env.STRAVA_ACCESS_TOKEN || '';

  if (process.env.MOCK_MODE === 'true') {
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

    // Save the run to our actual Prisma database
    // Note: We'd need an actual user ID here from the request.
    // For now, if we're in mock mode, we assume user_1 or a default user.
    const user = await prisma.paceflowUser.findFirst();
    if (user) {
      // Find or create course
      const course = await prisma.paceflowCourse.create({
        data: {
          name: "Mock Strava 5K",
          gpxData: {},
          totalElevationGain: 50.0
        }
      });

      await prisma.paceflowRunSession.create({
        data: {
          id: crypto.randomUUID(),
          userId: user.id,
          courseId: course.id,
          date: new Date(),
          totalTime: 300,
          avgPace: 5.5,
        }
      });
    }

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
