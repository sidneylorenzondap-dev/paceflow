import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { generatePacingCurve } from '../services/pacingService';
import { CourseSegment } from '../services/gpxParser';

import { prisma } from '../db';

const router = Router();

router.get('/curve', async (req, res) => {
  try {
    const courseId = req.query.courseId as string;
    const goalTimeSeconds = parseInt(req.query.goalTimeSeconds as string, 10);
    
    if (!courseId || isNaN(goalTimeSeconds)) {
      return res.status(400).json({ error: 'Missing courseId or goalTimeSeconds query params' });
    }

    const course = await prisma.course.findUnique({
      where: { id: courseId }
    });

    if (!course) {
      return res.status(404).json({ error: 'Course not found' });
    }

    const segments = course.gpxData as unknown as CourseSegment[];
    
    const curve = await generatePacingCurve(segments, goalTimeSeconds);

    res.status(200).json({ success: true, curve });
  } catch (error) {
    console.error('Error generating pacing curve:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

export default router;
