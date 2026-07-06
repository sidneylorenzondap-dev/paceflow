"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const validation_1 = require("../middleware/validation");
const telemetryService_1 = require("../services/telemetryService");
const router = (0, express_1.Router)();
router.post('/', validation_1.validateTelemetryPayload, async (req, res) => {
    try {
        const { sessionId, samples } = req.body;
        // Ingest the telemetry batch
        await (0, telemetryService_1.ingestTelemetryBatch)(sessionId, samples);
        res.status(202).json({ success: true, message: 'Telemetry batch queued for ingestion' });
    }
    catch (error) {
        console.error('Error ingesting telemetry:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});
exports.default = router;
