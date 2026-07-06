"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiCoach = void 0;
const generative_ai_1 = require("@google/generative-ai");
const apiKey = process.env.GEMINI_API_KEY || '';
const genAI = new generative_ai_1.GoogleGenerativeAI(apiKey);
class AiCoach {
    model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    lastInterventionTime = 0;
    cooldownMs = 30000; // 30 seconds between interventions
    async getCoachingCue(alert) {
        const now = Date.now();
        if (now - this.lastInterventionTime < this.cooldownMs) {
            return null; // On cooldown
        }
        try {
            const prompt = `You are an elite AI running coach. The runner's real-time telemetry triggered this alert: "${alert.message}". 
      Give a concise, single-sentence coaching instruction to correct their form (under 10 words). Example: "Shorten your stride; you're over-striding on the descent."`;
            const result = await this.model.generateContent(prompt);
            const cue = result.response.text().trim();
            this.lastInterventionTime = now;
            return cue;
        }
        catch (error) {
            console.error('Gemini API Error:', error);
            return null;
        }
    }
}
exports.AiCoach = AiCoach;
