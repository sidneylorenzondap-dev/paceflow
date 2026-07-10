"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupLiveCoachingSocket = void 0;
const ws_1 = require("ws");
const formAnalyzer_1 = require("../services/formAnalyzer");
const aiCoach_1 = require("../services/aiCoach");
const ttsPipeline_1 = require("../services/ttsPipeline");
const mockSimulator_1 = require("../services/mockSimulator");
const ghostPacer_1 = require("../services/ghostPacer");
const setupLiveCoachingSocket = (server) => {
    const wss = new ws_1.WebSocketServer({ noServer: true });
    server.on('upgrade', (request, socket, head) => {
        if (request.url === '/api/v1/live-coaching') {
            wss.handleUpgrade(request, socket, head, (ws) => {
                wss.emit('connection', ws, request);
            });
        }
        else {
            socket.destroy();
        }
    });
    wss.on('connection', (ws) => {
        console.log('Client connected for live coaching.');
        const analyzer = new formAnalyzer_1.FormAnalyzer();
        const coach = new aiCoach_1.AiCoach();
        const ghostPacer = new ghostPacer_1.GhostPacer();
        let startTime = Date.now();
        let isGhostRacing = false;
        ws.on('message', async (message) => {
            try {
                const payload = JSON.parse(message);
                if (payload.type === 'START_MOCK') {
                    if (process.env.MOCK_MODE === 'true') {
                        coach.setRunGoals({
                            distance: payload.distance,
                            paceSeconds: payload.paceSeconds,
                            strictness: payload.strictness
                        });
                        (0, mockSimulator_1.startMockSimulation)(ws, analyzer, coach, payload.distance, payload.paceSeconds, payload.strictness);
                    }
                    else {
                        ws.send(JSON.stringify({ error: 'Mock mode is not enabled on server.' }));
                    }
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
                const telemetryPayload = payload;
                const alert = analyzer.analyze(telemetryPayload);
                // Form Alerts
                if (alert) {
                    const cue = await coach.getCoachingCue(alert);
                    if (cue) {
                        const ttsPayload = await (0, ttsPipeline_1.generateTTS)(cue);
                        ws.send(ttsPayload);
                    }
                }
                // Ghost Racing Alerts (every 10 seconds approximation)
                if (isGhostRacing && Math.random() < 0.1) {
                    const elapsedMs = Date.now() - startTime;
                    const currentDistance = telemetryPayload.elevation || 0; // Using elevation as mock distance for now
                    const ghostCue = ghostPacer.compareWithGhost(elapsedMs, currentDistance);
                    if (ghostCue) {
                        const ghostAudio = await (0, ttsPipeline_1.generateTTS)(ghostCue);
                        ws.send(ghostAudio);
                    }
                }
            }
            catch (e) {
                console.error('Error processing telemetry socket message:', e);
            }
        });
        ws.on('close', () => {
            console.log('Client disconnected from live coaching.');
        });
    });
};
exports.setupLiveCoachingSocket = setupLiveCoachingSocket;
