"use strict";
// Simple in-memory database to store run history for the MVP
Object.defineProperty(exports, "__esModule", { value: true });
exports.db = void 0;
class MockDatabase {
    runs = [];
    userProfile = {
        id: 'user_1',
        subscriptionTier: 'premium',
        aiCredits: 10,
        activePlan: null,
        activePlanGoal: null
    };
    saveRun(run) {
        this.runs.push(run);
        console.log(`[Database] Saved run ${run.id} from ${run.source}. Total runs: ${this.runs.length}`);
    }
    getAllRuns() {
        return [...this.runs].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    }
    clearRuns() {
        this.runs = [];
    }
}
exports.db = new MockDatabase();
