import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import http from 'http';
import webhookRoutes from './api/webhooks';
import syncRoutes from './api/sync';
import courseRoutes from './api/courses';
import pacingRoutes from './api/pacing';
import simulationRoutes from './api/simulations';
import analyticsRoutes from './api/analytics';
import stravaRoutes from './api/strava';
import trainingRoutes from './api/training';
import userRoutes from './api/user';
import { setupLiveCoachingSocket } from './api/liveCoaching';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
// Keep last 100 logs in memory for debugging
export const recentLogs: string[] = [];
const originalConsoleError = console.error;
console.error = function (...args) {
  recentLogs.push(`[ERROR] ${new Date().toISOString()}: ${args.map(a => typeof a === 'object' ? JSON.stringify(a) : a).join(' ')}`);
  if (recentLogs.length > 100) recentLogs.shift();
  originalConsoleError.apply(console, args);
};

const originalConsoleLog = console.log;
console.log = function (...args) {
  recentLogs.push(`[INFO] ${new Date().toISOString()}: ${args.map(a => typeof a === 'object' ? JSON.stringify(a) : a).join(' ')}`);
  if (recentLogs.length > 100) recentLogs.shift();
  originalConsoleLog.apply(console, args);
};

app.use(express.json());

app.get('/api/v1/logs', (req, res) => {
  res.json({ logs: recentLogs });
});

// Routes
app.use('/api/v1/sync/wearable', syncRoutes);
app.use('/api/v1/webhooks', webhookRoutes);
app.use('/api/v1/courses', courseRoutes);
app.use('/api/v1/pacing', pacingRoutes);
app.use('/api/v1/simulations', simulationRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/v1/strava', stravaRoutes);
app.use('/api/v1/training', trainingRoutes);
app.use('/api/v1/user', userRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

const server = http.createServer(app);
setupLiveCoachingSocket(server);

server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
