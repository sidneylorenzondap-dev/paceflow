"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiCoach = void 0;
const generative_ai_1 = require("@google/generative-ai");
class AiCoach {
    get model() {
        const apiKey = process.env.GEMINI_API_KEY || '';
        const genAI = new generative_ai_1.GoogleGenerativeAI(apiKey);
        return genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
    }
    lastInterventionTime = 0;
    cooldownMs = 30000; // 30 seconds between interventions
    runGoals = {};
    setRunGoals(goals) {
        this.runGoals = goals;
    }
    async getCoachingCue(alert) {
        const now = Date.now();
        if (now - this.lastInterventionTime < this.cooldownMs) {
            return null; // On cooldown
        }
        if (process.env.MOCK_MODE === 'true') {
            const mockCues = [
                "Shorten your stride; you're over-striding on the incline.",
                "Keep your cadence up, pump your arms.",
                "Stay light on your feet, your ground contact time is increasing."
            ];
            this.lastInterventionTime = now;
            const randomCue = mockCues[Math.floor(Math.random() * mockCues.length)];
            console.log(`[Mock AiCoach] Generated cue: "${randomCue}"`);
            return randomCue;
        }
        try {
            let personaInstruction = "Act as an elite AI running coach.";
            if (this.runGoals.strictness === 'Cheerleader') {
                personaInstruction = "Act as an overly enthusiastic, supportive, and cheerful running coach.";
            }
            else if (this.runGoals.strictness === 'Drill Sergeant') {
                personaInstruction = "Act as an intense, demanding, and tough-love military drill sergeant.";
            }
            const paceGoalText = this.runGoals.paceSeconds ? `They are aiming for a pace of ${Math.floor(this.runGoals.paceSeconds / 60)}:${(this.runGoals.paceSeconds % 60).toString().padStart(2, '0')}/km.` : '';
            const distanceGoalText = this.runGoals.distance ? `Their goal distance is ${this.runGoals.distance}.` : '';
            const prompt = `${personaInstruction} The runner's real-time telemetry triggered this alert: "${alert.message}". 
      ${paceGoalText} ${distanceGoalText}
      The current weather heat index is around 85°F (factor this into pacing if necessary).
      Give a concise, single-sentence coaching instruction to correct their form or pace (under 10 words). Example: "Shorten your stride; you're over-striding on the descent."`;
            const result = await this.model.generateContent(prompt);
            const cue = result.response.text().trim();
            this.lastInterventionTime = now;
            return cue;
        }
        catch (error) {
            console.error('Gemini API Error:', error);
            return "Focus on your form, keep your cadence up.";
        }
    }
    async generateNutritionPlan(durationSecs, distanceMeters, heatIndex, dietPreference = 'Standard') {
        try {
            const kcalBurned = (durationSecs / 60) * 12; // Rough estimate: 12 kcal per min
            const sweatLossLiters = (durationSecs / 3600) * (0.5 + (heatIndex * 0.05));
            const prompt = `
        Act as an elite sports nutritionist. The user just completed a ${distanceMeters}m run in ${Math.round(durationSecs / 60)} minutes.
        The current heat index during their run was a factor of ${heatIndex}.
        Estimated calories burned: ${Math.round(kcalBurned)} kcal.
        Estimated fluid loss: ${sweatLossLiters.toFixed(2)} Liters.
        Dietary Preference: ${dietPreference}.

        Provide EXACTLY 3 hyper-personalized recovery meal options based on their dietary preference.
        Keep each option to one short sentence. Format as a bulleted list.
      `;
            const result = await this.model.generateContent(prompt);
            return result.response.text();
        }
        catch (e) {
            console.error('[AiCoach] Nutrition generation failed', e);
            return 'Failed to generate nutrition plan. Hydrate and eat balanced macros.';
        }
    }
    planCache = new Map();
    async generateTrainingPlan(goal, history) {
        try {
            const historyContext = history.length > 0
                ? `Here is their recent run history: ${JSON.stringify(history)}`
                : `They have no recent run history recorded.`;
            const prompt = `
        Act as an elite Olympic running coach. The user wants a 1-week micro-cycle training plan.
        Their goal is: ${goal}.
        ${historyContext}

        Adhere STRICTLY to verified coaching methodologies (e.g. the 80/20 rule where 80% of runs are easy, 20% are hard).
        If the user does not have a heart rate monitor, specify effort using RPE (Rate of Perceived Exertion) and the "Talk Test" (e.g., "Run at a pace where you can comfortably hold a conversation").
        
        OUTPUT EXACTLY AND ONLY VALID JSON. DO NOT WRAP IN MARKDOWN BACKTICKS. DO NOT INCLUDE ANY OTHER TEXT.
        The JSON MUST be an array of exactly 7 objects, representing Monday to Sunday.
        Schema:
        [
          {
            "day": "Monday",
            "type": "Easy" | "Interval" | "Long" | "Rest",
            "description": "Short description of the workout (e.g., '30 min easy run, conversational pace')",
            "targetDistanceMeters": 5000 // optional number if applicable
          }
        ]
      `;
            const result = await this.model.generateContent(prompt);
            let jsonText = result.response.text().trim();
            // Clean up markdown block if the model ignores the instruction
            if (jsonText.startsWith('\`\`\`json')) {
                jsonText = jsonText.replace(/^\`\`\`json\n/, '').replace(/\n\`\`\`$/, '');
            }
            else if (jsonText.startsWith('\`\`\`')) {
                jsonText = jsonText.replace(/^\`\`\`\n/, '').replace(/\n\`\`\`$/, '');
            }
            const generatedPlan = JSON.parse(jsonText);
            return generatedPlan;
        }
        catch (e) {
            console.error('[AiCoach] Training plan generation failed', e);
            throw new Error('Failed to generate training plan.');
        }
    }
    async adjustTrainingPlan(currentPlan, userFeedback) {
        try {
            const prompt = `
        Act as an elite Olympic running coach. 
        Here is the user's current 1-week training plan:
        ${JSON.stringify(currentPlan)}
        
        The user has provided the following feedback/request for adjustment:
        "${userFeedback}"
        
        Adjust the plan logically to accommodate their request. (e.g., if they are sick, turn today into a Rest day and shift workouts. If it's too hard, make it easier).
        
        OUTPUT EXACTLY AND ONLY VALID JSON. DO NOT WRAP IN MARKDOWN BACKTICKS. DO NOT INCLUDE ANY OTHER TEXT.
        The JSON MUST be an array of exactly 7 objects, representing Monday to Sunday.
        Schema:
        [
          {
            "day": "Monday",
            "type": "Easy" | "Interval" | "Long" | "Rest",
            "description": "Short description of the workout (e.g., '30 min easy run, conversational pace')",
            "targetDistanceMeters": 5000
          }
        ]
      `;
            const result = await this.model.generateContent(prompt);
            let jsonText = result.response.text().trim();
            if (jsonText.startsWith('\`\`\`json')) {
                jsonText = jsonText.replace(/^\`\`\`json\n/, '').replace(/\n\`\`\`$/, '');
            }
            else if (jsonText.startsWith('\`\`\`')) {
                jsonText = jsonText.replace(/^\`\`\`\n/, '').replace(/\n\`\`\`$/, '');
            }
            const generatedPlan = JSON.parse(jsonText);
            return generatedPlan;
        }
        catch (e) {
            console.error('[AiCoach] Plan adjustment failed', e);
            throw new Error('Failed to adjust training plan.');
        }
    }
}
exports.AiCoach = AiCoach;
