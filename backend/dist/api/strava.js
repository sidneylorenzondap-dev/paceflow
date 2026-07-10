"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const stravaService_1 = require("../services/stravaService");
const router = (0, express_1.Router)();
router.get('/import', async (req, res) => {
    try {
        const geojson = await (0, stravaService_1.importLatestStravaRun)();
        res.json(geojson);
    }
    catch (error) {
        console.error('Strava API Error:', error);
        res.status(500).json({ error: 'Failed to import from Strava' });
    }
});
exports.default = router;
