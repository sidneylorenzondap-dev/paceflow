import WebSocket from 'ws';
import { FormAnalyzer } from './formAnalyzer';
import { AiCoach } from './aiCoach';
import { TelemetrySamplePayload } from './telemetryService';
import { generateTTS } from './ttsPipeline';

export const startMockSimulation = (
  ws: WebSocket, 
  analyzer: FormAnalyzer, 
  coach: AiCoach,
  targetDistance?: string,
  targetPaceSeconds?: number,
  strictness?: string
) => {
  console.log('[MockSimulator] Starting mock telemetry stream...');
  
  let currentCadence = 175;
  let currentGct = 220;
  let heartRate = 140;
  let tick = 0;

  const intervalId = setInterval(async () => {
    tick++;

    // Introduce simulated fatigue after 5 seconds
    if (tick > 5) {
      currentCadence -= 1; // gradually drop cadence
      currentGct += 2;     // gradually increase GCT
      heartRate += 1;
    }

    const payload: TelemetrySamplePayload = {
      timestamp: Date.now(),
      lat: 37.7749 + (tick * 0.0001),
      lon: -122.4194,
      elevation: 10 + (tick * 0.5),
      cadence: currentCadence,
      gct: currentGct,
      verticalOscillation: 8.5,
      heartRate: heartRate
    };

    // Send the raw telemetry to the client so the UI can render the numbers
    ws.send(JSON.stringify({ type: 'TELEMETRY_UPDATE', data: payload }));

    // Run the backend analysis logic
    const alert = analyzer.analyze(payload);
    if (alert) {
      console.log(`[MockSimulator] Form alert triggered: ${alert.type}`);
      const cue = await coach.getCoachingCue(alert);
      if (cue) {
        const ttsPayload = await generateTTS(cue);
        ws.send(ttsPayload);
      }
    }

    // Stop after 30 seconds
    if (tick > 30) {
      clearInterval(intervalId);
      console.log('[MockSimulator] Finished mock telemetry stream.');
      ws.send(JSON.stringify({ type: 'SIMULATION_COMPLETE' }));
    }
  }, 1000); // Emit 1 sample per second for the mock

  ws.on('close', () => {
    clearInterval(intervalId);
  });
};
