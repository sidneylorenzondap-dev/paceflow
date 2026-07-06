"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateFatigueGeoJSON = generateFatigueGeoJSON;
function generateFatigueGeoJSON(samples) {
    const features = samples.map(sample => {
        // Simplified "Form Degradation" score. High score = worse form.
        let degradationScore = 0;
        if (sample.cadence && sample.cadence < 165) {
            degradationScore += (165 - sample.cadence);
        }
        if (sample.gct && sample.gct > 220) {
            degradationScore += (sample.gct - 220) / 10;
        }
        return {
            type: 'Feature',
            geometry: {
                type: 'Point',
                coordinates: [sample.lon, sample.lat] // GeoJSON format is [longitude, latitude]
            },
            properties: {
                timestamp: sample.timestamp.toString(), // BigInt to string
                elevation: sample.elevation,
                cadence: sample.cadence,
                gct: sample.gct,
                degradationScore,
                color: degradationScore > 5 ? 'red' : (degradationScore > 2 ? 'yellow' : 'green')
            }
        };
    });
    return {
        type: 'FeatureCollection',
        features
    };
}
