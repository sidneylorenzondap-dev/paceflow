"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const aiCoach_1 = require("../services/aiCoach");
const mockDb_1 = require("../services/mockDb");
const router = (0, express_1.Router)();
const aiCoach = new aiCoach_1.AiCoach();
router.get('/plan', async (req, res) => {
    try {
        const goal = req.query.goal || 'Improve 5K time';
        // Check subscription tier
        if (mockDb_1.db.userProfile.subscriptionTier === 'free') {
            const staticPlan = [
                { day: 'Monday', type: 'Rest', description: 'Active recovery or complete rest' },
                { day: 'Tuesday', type: 'Easy', description: '30 min easy run, conversational pace' },
                { day: 'Wednesday', type: 'Interval', description: 'Warmup, 4x400m hard, Cooldown' },
                { day: 'Thursday', type: 'Rest', description: 'Active recovery' },
                { day: 'Friday', type: 'Easy', description: '20 min easy run' },
                { day: 'Saturday', type: 'Rest', description: 'Rest day before long run' },
                { day: 'Sunday', type: 'Long', description: '60 min long run, easy pace' }
            ];
            mockDb_1.db.userProfile.activePlan = staticPlan;
            mockDb_1.db.userProfile.activePlanGoal = goal;
            return res.json({ plan: staticPlan });
        }
        // Premium users: Check history for baseline
        const history = mockDb_1.db.getAllRuns();
        if (history.length === 0) {
            // If no history, require a baseline test run
            return res.status(428).json({
                error: 'Baseline test required.',
                instruction: 'Please complete a 10-15 minute run at a conversational pace (RPE 3-4 or Talk Test) to establish your baseline fitness.'
            });
        }
        if (mockDb_1.db.userProfile.aiCredits <= 0) {
            return res.status(402).json({ error: 'Out of AI credits for this month.' });
        }
        // Deduct credit
        mockDb_1.db.userProfile.aiCredits -= 1;
        // Generate the 1-week training plan using AI
        const plan = await aiCoach.generateTrainingPlan(goal, history);
        mockDb_1.db.userProfile.activePlan = plan;
        mockDb_1.db.userProfile.activePlanGoal = goal;
        res.json({ plan, creditsRemaining: mockDb_1.db.userProfile.aiCredits });
    }
    catch (error) {
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
        if (mockDb_1.db.userProfile.subscriptionTier === 'free') {
            return res.status(403).json({ error: 'AI adjustments require a premium subscription.' });
        }
        if (mockDb_1.db.userProfile.aiCredits <= 0) {
            return res.status(402).json({ error: 'Out of AI credits for this month.' });
        }
        if (!mockDb_1.db.userProfile.activePlan) {
            return res.status(400).json({ error: 'No active plan found to adjust.' });
        }
        mockDb_1.db.userProfile.aiCredits -= 1;
        const adjustedPlan = await aiCoach.adjustTrainingPlan(mockDb_1.db.userProfile.activePlan, feedback);
        mockDb_1.db.userProfile.activePlan = adjustedPlan;
        res.json({ plan: adjustedPlan, creditsRemaining: mockDb_1.db.userProfile.aiCredits });
    }
    catch (error) {
        console.error('Training Plan Adjustment Error:', error);
        res.status(500).json({ error: 'Failed to adjust training plan' });
    }
});
exports.default = router;
