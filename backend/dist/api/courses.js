"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const gpxParser_1 = require("../services/gpxParser");
const db_1 = require("../db");
const router = (0, express_1.Router)();
router.post('/import', async (req, res) => {
    try {
        const { name, gpxDataString } = req.body;
        if (!name || !gpxDataString) {
            return res.status(400).json({ error: 'Missing name or gpxDataString' });
        }
        const segments = await (0, gpxParser_1.parseGpx)(gpxDataString);
        if (segments.length === 0) {
            return res.status(400).json({ error: 'Failed to parse GPX or no track points found' });
        }
        // Calculate total elevation gain
        let totalElevationGain = 0;
        for (let i = 1; i < segments.length; i++) {
            const eleDiff = segments[i].ele - segments[i - 1].ele;
            if (eleDiff > 0) {
                totalElevationGain += eleDiff;
            }
        }
        const course = await db_1.prisma.paceflowCourse.create({
            data: {
                name,
                gpxData: segments, // Storing parsed segments as JSON
                totalElevationGain,
                heatIndexFactor: 1.0 // Default baseline
            }
        });
        res.status(201).json({ success: true, course });
    }
    catch (error) {
        console.error('Error importing course:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});
exports.default = router;
