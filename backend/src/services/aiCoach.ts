import { GoogleGenerativeAI } from '@google/generative-ai';
import { FormAlert } from './formAnalyzer';

const apiKey = process.env.GEMINI_API_KEY || '';
const genAI = new GoogleGenerativeAI(apiKey);

export class AiCoach {
  private model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
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
      const sweatLossLiters = (durationSecs / 3600) * (heatIndex > 80 ? 1.5 : 0.8); // 1.5L/hr if hot

      const prompt = `You are an elite sports nutritionist. A runner just finished a run lasting ${Math.round(durationSecs / 60)} minutes, covering ${distanceMeters} meters in ${heatIndex}°F heat. 
      Estimated calorie burn: ${Math.round(kcalBurned)} kcal. Estimated sweat loss: ${sweatLossLiters.toFixed(1)} Liters.
      The runner's dietary preference is: **${dietPreference}**.
      
      Provide exactly 3 different personalized post-run recovery meal options that STRICTLY adhere to the ${dietPreference} diet. 
      Also include a brief hydration recommendation.
      Format your response beautifully using markdown bullet points and bold text for the meal titles. Do not include any intro or outro fluff.`;
      
      const result = await this.model.generateContent(prompt);
      return result.response.text().trim();
    } catch (error) {
      console.error('Gemini Nutrition Error:', error);
      return "Unable to generate nutrition plan at this time. Drink water and eat some carbs!";
    }
  }
}
