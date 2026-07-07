import { Router } from 'express';
import { importLatestStravaRun } from '../services/stravaService';

const router = Router();

router.get('/import', async (req, res) => {
  try {
    const geojson = await importLatestStravaRun();
    res.json(geojson);
  } catch (error) {
    console.error('Strava API Error:', error);
    res.status(500).json({ error: 'Failed to import from Strava' });
  }
});

export default router;
