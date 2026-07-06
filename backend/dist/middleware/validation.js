"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateTelemetryPayload = void 0;
const validateTelemetryPayload = (req, res, next) => {
    const { sessionId, samples } = req.body;
    if (!sessionId || typeof sessionId !== 'string') {
        return res.status(400).json({ error: 'Invalid or missing sessionId' });
    }
    if (!samples || !Array.isArray(samples) || samples.length === 0) {
        return res.status(400).json({ error: 'Invalid or missing samples array' });
    }
    // Basic validation of the first sample to ensure structure is correct
    const sample = samples[0];
    if (sample.timestamp === undefined || sample.lat === undefined || sample.lon === undefined) {
        return res.status(400).json({ error: 'Samples missing required fields (timestamp, lat, lon)' });
    }
    next();
};
exports.validateTelemetryPayload = validateTelemetryPayload;
