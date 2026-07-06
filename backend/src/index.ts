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
import { setupLiveCoachingSocket } from './api/liveCoaching';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/v1/sync/wearable', syncRoutes);
app.use('/api/v1/webhooks', webhookRoutes);
app.use('/api/v1/courses', courseRoutes);
app.use('/api/v1/pacing', pacingRoutes);
app.use('/api/v1/simulations', simulationRoutes);
app.use('/api/v1/analytics', analyticsRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

const server = http.createServer(app);
setupLiveCoachingSocket(server);

server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
