import { Router } from 'express';
import { generateFatigueGeoJSON } from '../services/fatigueHeatmap';
import { AiCoach } from '../services/aiCoach';
import { getWeatherDataForCourse } from '../services/weatherService';

import { prisma } from '../db';

const router = Router();
const coach = new AiCoach();

router.get('/nutrition', async (req, res) => {
  try {
    const durationSecs = Number(req.query.durationSecs) || 1800; // default 30 mins
    const distanceMeters = Number(req.query.distanceMeters) || 5000; // default 5k
    const lat = Number(req.query.lat) || 0;
    const lon = Number(req.query.lon) || 0;

    const weather = await getWeatherDataForCourse(lat, lon);
    const plan = await coach.generateNutritionPlan(durationSecs, distanceMeters, weather.heatIndex);
    
    res.json({ plan });
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate nutrition plan' });
  }
});

router.get('/fatigue-map', async (req, res) => {
  try {
    const sessionId = req.query.sessionId as string;
    
    if (!sessionId) {
      return res.status(400).json({ error: 'Missing sessionId query param' });
    }

    const samples = await prisma.telemetrySample.findMany({
      where: { sessionId },
      orderBy: { timestamp: 'asc' }
    });

    if (samples.length === 0) {
      return res.status(404).json({ error: 'No telemetry samples found for this session' });
    }

    const geojson = generateFatigueGeoJSON(samples);
    
    res.status(200).json({ success: true, mapData: geojson });
  } catch (error) {
    console.error('Error generating fatigue map:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

export default router;
