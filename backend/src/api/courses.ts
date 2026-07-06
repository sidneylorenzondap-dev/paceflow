import { Router } from 'express';
import { parseGpx } from '../services/gpxParser';
import { PrismaClient } from '@prisma/client';

import { prisma } from '../db';

const router = Router();

router.post('/import', async (req, res) => {
  try {
    const { name, gpxDataString } = req.body;
    
    if (!name || !gpxDataString) {
      return res.status(400).json({ error: 'Missing name or gpxDataString' });
    }

    const segments = await parseGpx(gpxDataString);
    
    if (segments.length === 0) {
      return res.status(400).json({ error: 'Failed to parse GPX or no track points found' });
    }

    // Calculate total elevation gain
    let totalElevationGain = 0;
    for (let i = 1; i < segments.length; i++) {
      const eleDiff = segments[i].ele - segments[i-1].ele;
      if (eleDiff > 0) {
        totalElevationGain += eleDiff;
      }
    }

    const course = await prisma.course.create({
      data: {
        name,
        gpxData: segments as any, // Storing parsed segments as JSON
        totalElevationGain,
        heatIndexFactor: 1.0 // Default baseline
      }
    });

    res.status(201).json({ success: true, course });
  } catch (error) {
    console.error('Error importing course:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

export default router;
