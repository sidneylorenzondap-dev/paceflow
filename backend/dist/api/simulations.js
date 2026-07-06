"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const monteCarloEngine_1 = require("../services/monteCarloEngine");
const router = (0, express_1.Router)();
router.post('/run', async (req, res) => {
    try {
        const { userId, courseId, goalTimeSeconds } = req.body;
        if (!userId || !courseId || typeof goalTimeSeconds !== 'number') {
            return res.status(400).json({ error: 'Missing userId, courseId, or goalTimeSeconds' });
        }
        const simulation = await (0, monteCarloEngine_1.runMonteCarloSimulation)(userId, courseId, goalTimeSeconds);
        res.status(200).json({ success: true, simulation });
    }
    catch (error) {
        console.error('Error running Monte Carlo simulation:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});
exports.default = router;
