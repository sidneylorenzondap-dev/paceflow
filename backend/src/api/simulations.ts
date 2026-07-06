import { Router } from 'express';
import { runMonteCarloSimulation } from '../services/monteCarloEngine';

const router = Router();

router.post('/run', async (req, res) => {
  try {
    const { userId, courseId, goalTimeSeconds } = req.body;
    
    if (!userId || !courseId || typeof goalTimeSeconds !== 'number') {
      return res.status(400).json({ error: 'Missing userId, courseId, or goalTimeSeconds' });
    }

    const simulation = await runMonteCarloSimulation(userId, courseId, goalTimeSeconds);
    
    res.status(200).json({ success: true, simulation });
  } catch (error) {
    console.error('Error running Monte Carlo simulation:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

export default router;
