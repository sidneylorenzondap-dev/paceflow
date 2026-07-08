import { GoogleGenerativeAI } from '@google/generative-ai';
import { FormAlert } from './formAnalyzer';

export class AiCoach {
  private get model() {
    const apiKey = process.env.GEMINI_API_KEY || '';
    const genAI = new GoogleGenerativeAI(apiKey);
    return genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
  }
  private lastInterventionTime = 0;
  private cooldownMs = 30000; // 30 seconds between interventions

  public async getCoachingCue(alert: FormAlert): Promise<string | null> {
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
      const prompt = `You are an elite AI running coach. The runner's real-time telemetry triggered this alert: "${alert.message}". 
      The current weather heat index is around 85°F (factor this into pacing if necessary).
      Give a concise, single-sentence coaching instruction to correct their form (under 10 words). Example: "Shorten your stride; you're over-striding on the descent."`;
      
      const result = await this.model.generateContent(prompt);
      const cue = result.response.text().trim();
      
      this.lastInterventionTime = now;
      return cue;
    } catch (error) {
      console.error('Gemini API Error:', error);
      return "Focus on your form, keep your cadence up.";
    }
  }

  public async generateNutritionPlan(durationSecs: number, distanceMeters: number, heatIndex: number, dietPreference: string = 'Standard'): Promise<string> {
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
    } catch (e) {
      console.error('[AiCoach] Nutrition generation failed', e);
      return 'Failed to generate nutrition plan. Hydrate and eat balanced macros.';
    }
  }

  private planCache: Map<string, string> = new Map();

  public async generateTrainingPlan(goal: string, history: any[]): Promise<string> {
    try {
      const historyHash = history.map(h => h.id).join(',');
      const cacheKey = `${goal}_${historyHash}`;
      
      if (this.planCache.has(cacheKey)) {
        console.log('[AiCoach] Returning cached training plan to save API credits');
        return this.planCache.get(cacheKey)!;
      }

      const historyContext = history.length > 0 
        ? `Here is their recent run history: ${JSON.stringify(history)}` 
        : `They have no recent run history recorded.`;

      const prompt = `
        Act as an elite Olympic running coach. The user wants a 1-week micro-cycle training plan.
        Their goal is: ${goal}.
        ${historyContext}

        First, analyze if their goal is realistic based on their history. If it's highly unrealistic (e.g. asking for a 2-hour marathon but their 5K pace is very slow), gently tell them it might take longer, but provide a step-up plan anyway to start their journey.
        Then, generate a personalized 7-day plan (Monday-Sunday).
        If their history shows low cadence or high heart rate, recommend specific drills to address it.
        Keep it concise, actionable, and formatted as a Markdown list.
      `;

      const result = await this.model.generateContent(prompt);
      const generatedPlan = result.response.text();
      
      this.planCache.set(cacheKey, generatedPlan);
      return generatedPlan;
    } catch (e) {
      console.error('[AiCoach] Training plan generation failed', e);
      return 'Failed to generate training plan. Please rest and try again tomorrow.';
    }
  }
}
