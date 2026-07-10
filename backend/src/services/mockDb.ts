// Simple in-memory database to store run history for the MVP

export interface RunRecord {
  id: string;
  date: string;
  distanceMeters: number;
  durationSecs: number;
  avgHeartRate: number;
  avgCadence: number;
  source: 'Strava' | 'LiveRun';
}

export interface TrainingWorkout {
  day: string;
  type: 'Easy' | 'Interval' | 'Long' | 'Rest' | 'Baseline';
  description: string;
  targetDistanceMeters?: number;
}

export interface UserProfile {
  id: string;
  subscriptionTier: 'free' | 'premium';
  aiCredits: number;
  activePlan: TrainingWorkout[] | null;
  activePlanGoal: string | null;
}

class MockDatabase {
  private runs: RunRecord[] = [];
  
  public userProfile: UserProfile = {
    id: 'user_1',
    subscriptionTier: 'premium',
    aiCredits: 10,
    activePlan: null,
    activePlanGoal: null
  };

  public saveRun(run: RunRecord) {
    this.runs.push(run);
    console.log(`[Database] Saved run ${run.id} from ${run.source}. Total runs: ${this.runs.length}`);
  }

  public getAllRuns(): RunRecord[] {
    return [...this.runs].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }

  public clearRuns() {
    this.runs = [];
  }
}

export const db = new MockDatabase();
