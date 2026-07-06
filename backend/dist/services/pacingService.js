"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generatePacingCurve = generatePacingCurve;
const weatherService_1 = require("./weatherService");
const physicsEngine_1 = require("./physicsEngine");
async function generatePacingCurve(segments, goalTimeSeconds) {
    if (segments.length === 0)
        return [];
    const totalDistance = segments[segments.length - 1].distance;
    const basePaceMinKm = (goalTimeSeconds / 60) / (totalDistance / 1000);
    const weather = await (0, weatherService_1.getWeatherDataForCourse)(segments[0].lat, segments[0].lon);
    const pacingCurve = [];
    let cumulativeTimeMs = 0;
    for (let i = 0; i < segments.length; i++) {
        const segment = segments[i];
        // Apply "Negative Split" strategy
        let strategyPace = basePaceMinKm;
        const progress = totalDistance > 0 ? segment.distance / totalDistance : 0;
        if (progress < 0.3) {
            strategyPace *= 1.02; // 2% slower initially
        }
        else if (progress > 0.7) {
            strategyPace *= 0.98; // 2% faster finish
        }
        const { adjustedPaceMs } = (0, physicsEngine_1.calculatePacingAdjustment)(segment, weather, strategyPace);
        const segmentDist = i === 0 ? 0 : segment.distance - segments[i - 1].distance;
        cumulativeTimeMs += (segmentDist * adjustedPaceMs);
        pacingCurve.push({
            distanceOffset: segment.distance,
            targetPaceMsPerMeter: adjustedPaceMs,
            targetPaceMinKm: (adjustedPaceMs * 1000) / 60000,
            cumulativeTimeMs
        });
    }
    return pacingCurve;
}
