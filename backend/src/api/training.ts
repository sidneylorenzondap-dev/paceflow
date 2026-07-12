import { Router } from 'express';
import { AiCoach } from '../services/aiCoach';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';

const router = Router();
const aiCoach = new AiCoach();

router.get('/plan', requireAuth, async (req, res) => {
  try {
    const goal = (req.query.goal as string) || 'Improve 5K time';
    
    // Check if user already has a saved plan for this exact goal
    const existingPlan = await prisma.paceflowTrainingPlan.findFirst({
      where: { userId: req.user.id, goal: goal }
    });

    if (existingPlan) {
      // Set it as active and return for free
      await prisma.paceflowUser.update({
        where: { id: req.user.id },
        data: { activePlan: existingPlan.planData, activePlanGoal: goal }
      });
      return res.json({ plan: existingPlan.planData, creditsRemaining: req.user.aiCredits, isCached: true });
    }

    // Check history for baseline
    const history = await prisma.paceflowRunSession.findMany({ where: { userId: req.user.id } });
    if (history.length === 0) {
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
      distanceMeters: 5000,
      durationSecs: h.totalTime,
      avgHeartRate: 150,
      avgCadence: 170
    }));
    const plan = await aiCoach.generateTrainingPlan(goal, formattedHistory);
    
    // Save to PaceflowTrainingPlan and update user's active plan
    await prisma.$transaction([
      prisma.paceflowTrainingPlan.create({
        data: {
          userId: req.user.id,
          goal: goal,
          planData: plan
        }
      }),
      prisma.paceflowUser.update({
        where: { id: req.user.id },
        data: { activePlan: plan, activePlanGoal: goal }
      })
    ]);

    res.json({ plan, creditsRemaining: updatedUser.aiCredits, isCached: false });
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

router.get('/history', requireAuth, async (req, res) => {
  try {
    const history = await prisma.paceflowRunSession.findMany({
      where: { userId: req.user.id },
      orderBy: { date: 'desc' },
      include: {
        course: {
          select: { name: true }
        }
      }
    });
    res.json({ history });
  } catch (error) {
    console.error('Fetch History Error:', error);
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

router.get('/saved-plans', requireAuth, async (req, res) => {
  try {
    const plans = await prisma.paceflowTrainingPlan.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' }
    });
    res.json({ plans });
  } catch (error) {
    console.error('Fetch Saved Plans Error:', error);
    res.status(500).json({ error: 'Failed to fetch saved plans' });
  }
});

router.post('/active-plan', requireAuth, async (req, res) => {
  try {
    const { planId } = req.body;
    if (!planId) return res.status(400).json({ error: 'planId is required' });

    const plan = await prisma.paceflowTrainingPlan.findFirst({
      where: { id: planId, userId: req.user.id }
    });

    if (!plan) return res.status(404).json({ error: 'Plan not found' });

    await prisma.paceflowUser.update({
      where: { id: req.user.id },
      data: { activePlan: plan.planData, activePlanGoal: plan.goal }
    });

    res.json({ success: true, plan: plan.planData, goal: plan.goal });
  } catch (error) {
    console.error('Set Active Plan Error:', error);
    res.status(500).json({ error: 'Failed to set active plan' });
  }
});


export default router;
