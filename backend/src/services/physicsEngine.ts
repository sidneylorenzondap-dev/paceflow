import { CourseSegment } from './gpxParser';
import { WeatherData } from './weatherService';

export interface PacingAdjustment {
  basePaceMs: number; // base pace in milliseconds per meter
  adjustedPaceMs: number; // adjusted pace in ms per meter
}

export function calculatePacingAdjustment(
  segment: CourseSegment, 
  weather: WeatherData, 
  basePaceMinKm: number
): PacingAdjustment {
  // Base pace in ms per meter
  const basePaceMs = (basePaceMinKm * 60 * 1000) / 1000;
  
  let adjustedPaceMs = basePaceMs;

  // 1. Adjust for Slope (simplified metabolic cost)
  // Uphill: Every 1% gradient slows pace by ~3.5%
  // Downhill: Every 1% gradient speeds up pace by ~1.5%
  if (segment.gradient > 0) {
    adjustedPaceMs *= (1 + (segment.gradient * 0.035));
  } else if (segment.gradient < 0) {
    adjustedPaceMs *= (1 + (segment.gradient * 0.015)); 
  }

  // 2. Adjust for Weather
  // High heat index adds fatigue, slowing pace
  if (weather.heatIndex > 80) {
    const heatPenalty = (weather.heatIndex - 80) * 0.005; // 0.5% slower per degree above 80
    adjustedPaceMs *= (1 + heatPenalty);
  }

  // Headwind penalty
  if (weather.windResistance > 0) {
    adjustedPaceMs *= (1 + (weather.windResistance * 0.01)); // 1% slower per mph headwind
  }

  return {
    basePaceMs,
    adjustedPaceMs
  };
}
