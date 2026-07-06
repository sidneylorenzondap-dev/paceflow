import { prisma } from '../db';

export interface TelemetrySamplePayload {
  timestamp: number;
  lat: number;
  lon: number;
  elevation: number;
  cadence?: number;
  gct?: number;
  verticalOscillation?: number;
  heartRate?: number;
}

export const ingestTelemetryBatch = async (sessionId: string, samples: TelemetrySamplePayload[]) => {
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
  await prisma.telemetrySample.createMany({
    data: records,
    skipDuplicates: true // Avoid failing on duplicated timestamps from retries
  });
};
