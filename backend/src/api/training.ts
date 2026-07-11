import { Router } from 'express';
import { AiCoach } from '../services/aiCoach';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';

const router = Router();
const aiCoach = new AiCoach();

router.get('/plan', requireAuth, async (req, res) => {
  try {
    const goal = (req.query.goal as string) || 'Improve 5K time';
    
    // Check subscription tier
    if (req.user.subscriptionTier === 'free') {
      const staticPlan: any[] = [
        { day: 'Monday', type: 'Rest', description: 'Active recovery or complete rest' },
        { day: 'Tuesday', type: 'Easy', description: '30 min easy run, conversational pace' },
        { day: 'Wednesday', type: 'Interval', description: 'Warmup, 4x400m hard, Cooldown' },
        { day: 'Thursday', type: 'Rest', description: 'Active recovery' },
        { day: 'Friday', type: 'Easy', description: '20 min easy run' },
        { day: 'Saturday', type: 'Rest', description: 'Rest day before long run' },
        { day: 'Sunday', type: 'Long', description: '60 min long run, easy pace' }
      ];
      await prisma.paceflowUser.update({
        where: { id: req.user.id },
        data: { activePlan: staticPlan, activePlanGoal: goal }
      });
      return res.json({ plan: staticPlan });
    }

    // Premium users: Check history for baseline
    const history = await prisma.paceflowRunSession.findMany({ where: { userId: req.user.id } });
    if (history.length === 0) {
      // If no history, require a baseline test run
      return res.status(428).json({ 
        error: 'Baseline test required.', 
        instruction: 'Please complete a 10-15 minute run at a conversational pace (RPE 3-4 or Talk Test) to establish your baseline fitness.' 
      });
    }

    if (req.user.aiCredits <= 0) {
      return res.status(402).json({ error: 'Out of AI credits for this month.' });
    }

    // Deduct credit
    const updatedUser = await prisma.paceflowUser.update({
      where: { id: req.user.id },
      data: { aiCredits: req.user.aiCredits - 1 }
    });

    // Generate the 1-week training plan using AI
    const formattedHistory = history.map(h => ({
      date: h.date.toISOString(),
      distanceMeters: 5000, // mock distance since it's not in schema
      durationSecs: h.totalTime,
      avgHeartRate: 150,
      avgCadence: 170
    }));
    const plan = await aiCoach.generateTrainingPlan(goal, formattedHistory);
    
    await prisma.paceflowUser.update({
      where: { id: req.user.id },
      data: { activePlan: plan, activePlanGoal: goal }
    });

    res.json({ plan, creditsRemaining: updatedUser.aiCredits });
  } catch (error) {
    console.error('Training Plan Error:', error);
    res.status(500).json({ error: 'Failed to generate training plan' });
  }
});

router.post('/plan/adjust', requireAuth, async (req, res) => {
  try {
    const { feedback } = req.body;
    if (!feedback) {
      return res.status(400).json({ error: 'Feedback message is required.' });
    }

    if (req.user.subscriptionTier === 'free') {
      return res.status(403).json({ error: 'AI adjustments require a premium subscription.' });
    }

    if (req.user.aiCredits <= 0) {
      return res.status(402).json({ error: 'Out of AI credits for this month.' });
    }

    if (!req.user.activePlan) {
      return res.status(400).json({ error: 'No active plan found to adjust.' });
    }

    const updatedUser = await prisma.paceflowUser.update({
      where: { id: req.user.id },
      data: { aiCredits: req.user.aiCredits - 1 }
    });

    const adjustedPlan = await aiCoach.adjustTrainingPlan(req.user.activePlan, feedback);
    
    await prisma.paceflowUser.update({
      where: { id: req.user.id },
      data: { activePlan: adjustedPlan }
    });

    res.json({ plan: adjustedPlan, creditsRemaining: updatedUser.aiCredits });
  } catch (error) {
    console.error('Training Plan Adjustment Error:', error);
    res.status(500).json({ error: 'Failed to adjust training plan' });
  }
});

router.post('/session/save', requireAuth, async (req, res) => {
  try {
    const { totalTimeSecs, distanceMeters } = req.body;
    
    // Fallbacks if Flutter doesn't send them
    const time = totalTimeSecs || 900; // 15 mins
    const dist = distanceMeters || 5000; // 5k
    const avgPace = (time / 60) / (dist / 1000); // min/km

    let course = await prisma.paceflowCourse.findFirst();
    if (!course) {
      course = await prisma.paceflowCourse.create({
        data: { name: 'Free Run', gpxData: {}, totalElevationGain: 0 }
      });
    }

    const session = await prisma.paceflowRunSession.create({
      data: {
        userId: req.user.id,
        courseId: course.id,
        date: new Date(),
        totalTime: time,
        avgPace: avgPace,
      }
    });

    res.json({ success: true, session });
  } catch (error) {
    console.error('Save Session Error:', error);
    res.status(500).json({ error: 'Failed to save run session' });
  }
});

export default router;
