"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const client_1 = require("@prisma/client");
const fatigueHeatmap_1 = require("../services/fatigueHeatmap");
const router = (0, express_1.Router)();
const prisma = new client_1.PrismaClient();
router.get('/fatigue-map', async (req, res) => {
    try {
        const sessionId = req.query.sessionId;
        if (!sessionId) {
            return res.status(400).json({ error: 'Missing sessionId query param' });
        }
        const samples = await prisma.telemetrySample.findMany({
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
