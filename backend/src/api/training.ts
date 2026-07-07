import { Router } from 'express';
import { AiCoach } from '../services/aiCoach';
import { db } from '../services/mockDb';

const router = Router();
const aiCoach = new AiCoach();

router.get('/plan', async (req, res) => {
  try {
    const goal = (req.query.goal as string) || 'Improve 5K time';
    
    // Fetch user history from our mock DB
    const history = db.getAllRuns();

    // Generate the 1-week training plan using AI
    const plan = await aiCoach.generateTrainingPlan(goal, history);
    
    res.json({ plan });
  } catch (error) {
    console.error('Training Plan Error:', error);
    res.status(500).json({ error: 'Failed to generate training plan' });
  }
});

export default router;
