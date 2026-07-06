"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const router = (0, express_1.Router)();
// Endpoint for Garmin Connect webhooks
router.post('/garmin', (req, res) => {
    // TODO: Validate Garmin signature and ingest payload
    console.log('Received Garmin webhook:', req.body);
    res.status(200).send('OK');
});
// Endpoint for Apple HealthKit (via server-to-server or iOS app relay)
router.post('/apple-health', (req, res) => {
    // TODO: Validate payload and ingest
    console.log('Received Apple Health webhook:', req.body);
    res.status(200).send('OK');
});
exports.default = router;
