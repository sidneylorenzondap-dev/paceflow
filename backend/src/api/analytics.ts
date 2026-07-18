import { Router } from 'express';
import { generateFatigueGeoJSON } from '../services/fatigueHeatmap';
import { AiCoach } from '../services/aiCoach';
import { getWeatherDataForCourse } from '../services/weatherService';

import { prisma } from '../db';

import { requireAuth } from '../middleware/auth';

const router = Router();
const coach = new AiCoach();

router.get('/nutrition', requireAuth, async (req, res) => {
  try {
    const durationSecs = Number(req.query.durationSecs) || 1800; // default 30 mins
    const distanceMeters = Number(req.query.distanceMeters) || 5000; // default 5k
    const lat = Number(req.query.lat) || 0;
    const lon = Number(req.query.lon) || 0;
    const diet = (req.query.diet as string) || 'Standard';

    if (req.user.subscriptionTier === 'free') {
      const type = distanceMeters > 15000 ? 'Long Run' : (distanceMeters > 5000 && durationSecs < 2400) ? 'Speedwork' : 'Easy Run';
      const staticRec = await prisma.paceflowStaticRecovery.findFirst({
        where: { type }
      });
      if (staticRec) {
        const advice = staticRec.advice as any;
        return res.json({ 
          plan: `**Static Recovery Plan (${type}):**\n\n**Nutrition:** ${advice.nutrition}\n**Hydration:** ${advice.hydration}\n**Mobility:** ${advice.mobility.join(', ')}\n**Sleep:** ${advice.sleep}` 
        });
      }
    }

    if (req.user.aiCredits <= 0) {
      return res.status(402).json({ error: 'Out of AI credits for this month. Upgrade to Premium for unlimited AI analysis.' });
    }

    const weather = await getWeatherDataForCourse(lat, lon);
    const plan = await coach.generateNutritionPlan(durationSecs, distanceMeters, weather.heatIndex, diet);
    
    // Deduct credit
    await prisma.paceflowUser.update({
      where: { id: req.user.id },
      data: { aiCredits: req.user.aiCredits - 1 }
    });

    res.json({ plan });
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate nutrition plan' });
  }
});

router.get('/fatigue-map', requireAuth, async (req, res) => {
  try {
    const sessionId = req.query.sessionId as string;
    
    if (!sessionId) {
      return res.status(400).json({ error: 'Missing sessionId query param' });
    }

    const samples = await prisma.paceflowTelemetrySample.findMany({
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
