"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const fatigueHeatmap_1 = require("../services/fatigueHeatmap");
const aiCoach_1 = require("../services/aiCoach");
const weatherService_1 = require("../services/weatherService");
const db_1 = require("../db");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
const coach = new aiCoach_1.AiCoach();
router.get('/nutrition', auth_1.requireAuth, async (req, res) => {
    try {
        const durationSecs = Number(req.query.durationSecs) || 1800; // default 30 mins
        const distanceMeters = Number(req.query.distanceMeters) || 5000; // default 5k
        const lat = Number(req.query.lat) || 0;
        const lon = Number(req.query.lon) || 0;
        const diet = req.query.diet || 'Standard';
        const weather = await (0, weatherService_1.getWeatherDataForCourse)(lat, lon);
        const plan = await coach.generateNutritionPlan(durationSecs, distanceMeters, weather.heatIndex, diet);
        res.json({ plan });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to generate nutrition plan' });
    }
});
router.get('/fatigue-map', auth_1.requireAuth, async (req, res) => {
    try {
        const sessionId = req.query.sessionId;
        if (!sessionId) {
            return res.status(400).json({ error: 'Missing sessionId query param' });
        }
        const samples = await db_1.prisma.paceflowTelemetrySample.findMany({
            where: { sessionId },
            orderBy: { timestamp: 'asc' }
        });
        if (samples.length === 0) {
            return res.status(404).json({ error: 'No telemetry samples found for this session' });
        }
        const geojson = (0, fatigueHeatmap_1.generateFatigueGeoJSON)(samples);
        res.status(200).json({ success: true, mapData: geojson });
    }
    catch (error) {
        console.error('Error generating fatigue map:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});
exports.default = router;
