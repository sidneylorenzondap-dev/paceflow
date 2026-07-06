"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupLiveCoachingSocket = void 0;
const ws_1 = __importDefault(require("ws"));
const formAnalyzer_1 = require("../services/formAnalyzer");
const aiCoach_1 = require("../services/aiCoach");
const ttsPipeline_1 = require("../services/ttsPipeline");
const setupLiveCoachingSocket = (server) => {
    const wss = new ws_1.default.Server({ noServer: true });
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
        ws.on('message', async (message) => {
            try {
                const payload = JSON.parse(message);
                const alert = analyzer.analyze(payload);
                if (alert) {
                    const cue = await coach.getCoachingCue(alert);
                    if (cue) {
                        const ttsPayload = await (0, ttsPipeline_1.generateTTS)(cue);
                        ws.send(ttsPayload);
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
