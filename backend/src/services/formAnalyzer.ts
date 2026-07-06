import { TelemetrySamplePayload } from './telemetryService';

export interface FormAlert {
  type: 'cadence_drop' | 'gct_increase' | 'vertical_oscillation_shift';
  message: string;
  severity: 'low' | 'medium' | 'high';
}

export class FormAnalyzer {
  private baselineCadence: number | null = null;
  private baselineGct: number | null = null;
  
  public analyze(sample: TelemetrySamplePayload): FormAlert | null {
    if (sample.cadence) {
      if (!this.baselineCadence) {
        this.baselineCadence = sample.cadence;
      } else {
        const drop = (this.baselineCadence - sample.cadence) / this.baselineCadence;
        if (drop > 0.05) {
          return { type: 'cadence_drop', message: 'Cadence dropped by >5%', severity: 'medium' };
        }
      }
    }

    if (sample.gct) {
      if (!this.baselineGct) {
        this.baselineGct = sample.gct;
      } else {
        if (sample.gct > this.baselineGct + 15) { // 15ms increase
          return { type: 'gct_increase', message: 'Ground contact time increasing', severity: 'medium' };
        }
      }
    }
    
    return null;
  }
}
