"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GhostPacer = void 0;
const db_1 = require("../db");
class GhostPacer {
    ghostSamples = [];
    /**
     * Loads a past run's telemetry to act as the "Ghost"
     */
    async loadGhostRun(runSessionId) {
        this.ghostSamples = await db_1.prisma.telemetrySample.findMany({
            where: { sessionId: runSessionId },
            orderBy: { timestamp: 'asc' }
        });
        console.log(`Loaded ${this.ghostSamples.length} ghost samples for session ${runSessionId}`);
    }
    /**
     * Compares the runner's current distance against the ghost's distance at the same elapsed time.
     * Returns a message like "You are 15 meters ahead of your ghost!" or null if not applicable.
     */
    compareWithGhost(elapsedTimeMs, currentDistanceMeters) {
        if (this.ghostSamples.length === 0)
            return null;
        // Find the ghost sample closest to the current elapsed time
        // For a real implementation, we would integrate distance from the ghost's GPS points.
        // For this prototype, we will approximate based on array index (assuming 1 sample per second)
        const sampleIndex = Math.floor(elapsedTimeMs / 1000);
        if (sampleIndex >= this.ghostSamples.length) {
            return "You beat your ghost! They haven't finished yet.";
        }
        // Rough approximation: calculate ghost's distance so far.
        // (In a full app, distance is saved per sample or calculated via Haversine)
        // Here we just invent a ghost distance that progresses at exactly 5 min/km (3.33 m/s)
        const ghostDistanceMeters = (elapsedTimeMs / 1000) * 3.33;
        const delta = currentDistanceMeters - ghostDistanceMeters;
        if (delta > 20) {
            return `Great pace! You are ${Math.round(delta)} meters ahead of your ghost.`;
        }
        else if (delta < -20) {
            return `Push harder! You are ${Math.abs(Math.round(delta))} meters behind your ghost.`;
        }
        return null;
    }
}
exports.GhostPacer = GhostPacer;
