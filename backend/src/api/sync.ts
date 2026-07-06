import { Router } from 'express';
import { validateTelemetryPayload } from '../middleware/validation';
import { ingestTelemetryBatch } from '../services/telemetryService';

const router = Router();

router.post('/', validateTelemetryPayload, async (req, res) => {
  try {
    const { sessionId, samples } = req.body;
    
    // Ingest the telemetry batch
    await ingestTelemetryBatch(sessionId, samples);
    
    res.status(202).json({ success: true, message: 'Telemetry batch queued for ingestion' });
  } catch (error) {
    console.error('Error ingesting telemetry:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

export default router;
