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

class MockDatabase {
  private runs: RunRecord[] = [];

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
