import { Router } from 'express';
import { AiCoach } from '../services/aiCoach';
import { db } from '../services/mockDb';

const router = Router();
const aiCoach = new AiCoach();

router.get('/plan', async (req, res) => {
  try {
    const goal = (req.query.goal as string) || 'Improve 5K time';
    
    // Check subscription tier
    if (db.userProfile.subscriptionTier === 'free') {
      const staticPlan: any[] = [
        { day: 'Monday', type: 'Rest', description: 'Active recovery or complete rest' },
        { day: 'Tuesday', type: 'Easy', description: '30 min easy run, conversational pace' },
        { day: 'Wednesday', type: 'Interval', description: 'Warmup, 4x400m hard, Cooldown' },
        { day: 'Thursday', type: 'Rest', description: 'Active recovery' },
        { day: 'Friday', type: 'Easy', description: '20 min easy run' },
        { day: 'Saturday', type: 'Rest', description: 'Rest day before long run' },
        { day: 'Sunday', type: 'Long', description: '60 min long run, easy pace' }
      ];
      db.userProfile.activePlan = staticPlan;
      db.userProfile.activePlanGoal = goal;
      return res.json({ plan: staticPlan });
    }

    // Premium users: Check history for baseline
    const history = db.getAllRuns();
    if (history.length === 0) {
      // If no history, require a baseline test run
      return res.status(428).json({ 
        error: 'Baseline test required.', 
        instruction: 'Please complete a 10-15 minute run at a conversational pace (RPE 3-4 or Talk Test) to establish your baseline fitness.' 
      });
    }

    if (db.userProfile.aiCredits <= 0) {
      return res.status(402).json({ error: 'Out of AI credits for this month.' });
    }

    // Deduct credit
    db.userProfile.aiCredits -= 1;

    // Generate the 1-week training plan using AI
    const plan = await aiCoach.generateTrainingPlan(goal, history);
    
    db.userProfile.activePlan = plan;
    db.userProfile.activePlanGoal = goal;

    res.json({ plan, creditsRemaining: db.userProfile.aiCredits });
  } catch (error) {
    console.error('Training Plan Error:', error);
    res.status(500).json({ error: 'Failed to generate training plan' });
  }
});

router.post('/plan/adjust', async (req, res) => {
  try {
    const { feedback } = req.body;
    if (!feedback) {
      return res.status(400).json({ error: 'Feedback message is required.' });
    }

    if (db.userProfile.subscriptionTier === 'free') {
      return res.status(403).json({ error: 'AI adjustments require a premium subscription.' });
    }

    if (db.userProfile.aiCredits <= 0) {
      return res.status(402).json({ error: 'Out of AI credits for this month.' });
    }

    if (!db.userProfile.activePlan) {
      return res.status(400).json({ error: 'No active plan found to adjust.' });
    }

    db.userProfile.aiCredits -= 1;

    const adjustedPlan = await aiCoach.adjustTrainingPlan(db.userProfile.activePlan, feedback);
    db.userProfile.activePlan = adjustedPlan;

    res.json({ plan: adjustedPlan, creditsRemaining: db.userProfile.aiCredits });
  } catch (error) {
    console.error('Training Plan Adjustment Error:', error);
    res.status(500).json({ error: 'Failed to adjust training plan' });
  }
});

export default router;
