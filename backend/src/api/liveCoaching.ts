import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';
import { FormAnalyzer } from '../services/formAnalyzer';
import { AiCoach } from '../services/aiCoach';
import { generateTTS } from '../services/ttsPipeline';
import { TelemetrySamplePayload } from '../services/telemetryService';
import { startMockSimulation } from '../services/mockSimulator';
import { GhostPacer } from '../services/ghostPacer';

import { createClient } from '@supabase/supabase-js';
import { prisma } from '../db';

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_ANON_KEY || '';
const supabase = createClient(supabaseUrl, supabaseKey);

export const setupLiveCoachingSocket = (server: Server) => {
  const wss = new WebSocketServer({ noServer: true });

  server.on('upgrade', (request, socket, head) => {
    if (request.url?.startsWith('/api/v1/live-coaching')) {
      wss.handleUpgrade(request, socket, head, (ws: WebSocket) => {
        wss.emit('connection', ws, request);
      });
    } else {
      socket.destroy();
    }
  });

  wss.on('connection', (ws: WebSocket, request: any) => {
    console.log('Client connected for live coaching.');
    
    let isAuthenticated = false;
    let authPromise: Promise<boolean> | null = null;
    
    // Auth Check
    const url = new URL(request.url, `http://${request.headers.host}`);
    const token = url.searchParams.get('token');
    
    if (!token) {
      ws.send(JSON.stringify({ error: 'Missing token' }));
      ws.close();
      return;
    }

    authPromise = supabase.auth.getUser(token).then(({ data: { user }, error }) => {
      if (error || !user) {
        ws.send(JSON.stringify({ error: 'Invalid token' }));
        ws.close();
        return false;
      }
      isAuthenticated = true;
      return true;
    });

    const analyzer = new FormAnalyzer();
    const coach = new AiCoach();
    const ghostPacer = new GhostPacer();
    let startTime = Date.now();
    let isGhostRacing = false;

    ws.on('message', async (message: string) => {
      // Wait for auth to complete before processing any messages
      if (authPromise) {
        const isValid = await authPromise;
        if (!isValid) return;
      }

      try {
        const payload = JSON.parse(message);
        
        if (payload.type === 'START_MOCK') {
          // Allow mock runs for any authenticated user
          coach.setRunGoals({
            distance: payload.distance,
            paceSeconds: payload.paceSeconds,
            strictness: payload.strictness
          });
          startMockSimulation(ws, analyzer, coach, payload.distance, payload.paceSeconds, payload.strictness);
          return;
        }

        if (payload.type === 'START_GHOST') {
          coach.setRunGoals({
            distance: payload.distance,
            paceSeconds: payload.paceSeconds,
            strictness: payload.strictness
          });
          await ghostPacer.loadGhostRun(payload.ghostSessionId);
          isGhostRacing = true;
          startTime = Date.now(); // reset start time for the race
          ws.send(JSON.stringify({ message: 'Ghost race started! 3..2..1.. GO!' }));
          return;
        }

        // Normal real telemetry processing
        const telemetryPayload: TelemetrySamplePayload = payload;
        const alert = analyzer.analyze(telemetryPayload);
        
        // Form Alerts
        if (alert) {
          const cue = await coach.getCoachingCue(alert);
          if (cue) {
            const ttsPayload = await generateTTS(cue);
            ws.send(ttsPayload);
          }
        }

        // Ghost Racing Alerts (every 10 seconds approximation)
        if (isGhostRacing && Math.random() < 0.1) {
          const elapsedMs = Date.now() - startTime;
          const currentDistance = telemetryPayload.elevation || 0; // Using elevation as mock distance for now
          const ghostCue = ghostPacer.compareWithGhost(elapsedMs, currentDistance);
          if (ghostCue) {
            const ghostAudio = await generateTTS(ghostCue);
            ws.send(ghostAudio);
          }
        }
      } catch (e) {
        console.error('Error processing telemetry socket message:', e);
      }
    });

    ws.on('close', () => {
      console.log('Client disconnected from live coaching.');
    });
  });
};
