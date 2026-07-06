"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getWeatherDataForCourse = getWeatherDataForCourse;
async function getWeatherDataForCourse(lat, lon) {
    // Mock external API call for now
    return {
        heatIndex: 85, // F
        windResistance: 5 // mph headwind
    };
}
