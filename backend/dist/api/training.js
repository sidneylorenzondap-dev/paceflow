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
        // Fetch user history from our mock DB
        const history = mockDb_1.db.getAllRuns();
        // Generate the 1-week training plan using AI
        const plan = await aiCoach.generateTrainingPlan(goal, history);
        res.json({ plan });
    }
    catch (error) {
        console.error('Training Plan Error:', error);
        res.status(500).json({ error: 'Failed to generate training plan' });
    }
});
exports.default = router;
