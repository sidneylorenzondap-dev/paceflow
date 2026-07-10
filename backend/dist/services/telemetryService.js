"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ingestTelemetryBatch = void 0;
const db_1 = require("../db");
const ingestTelemetryBatch = async (sessionId, samples) => {
    // We use createMany for high-throughput insertion.
    // 100Hz telemetry means 100 samples per second.
    const records = samples.map(sample => ({
        sessionId,
        timestamp: BigInt(sample.timestamp),
        lat: sample.lat,
        lon: sample.lon,
        elevation: sample.elevation,
        cadence: sample.cadence,
        gct: sample.gct,
        verticalOscillation: sample.verticalOscillation,
        heartRate: sample.heartRate
    }));
    // Perform bulk insert
    await db_1.prisma.telemetrySample.createMany({
        data: records,
        skipDuplicates: true // Avoid failing on duplicated timestamps from retries
    });
};
exports.ingestTelemetryBatch = ingestTelemetryBatch;
