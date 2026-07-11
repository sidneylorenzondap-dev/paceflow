"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const pacingService_1 = require("../services/pacingService");
const db_1 = require("../db");
const router = (0, express_1.Router)();
router.get('/curve', async (req, res) => {
    try {
        const courseId = req.query.courseId;
        const goalTimeSeconds = parseInt(req.query.goalTimeSeconds, 10);
        if (!courseId || isNaN(goalTimeSeconds)) {
            return res.status(400).json({ error: 'Missing courseId or goalTimeSeconds query params' });
        }
        const course = await db_1.prisma.paceflowCourse.findUnique({
            where: { id: courseId }
        });
        if (!course) {
            return res.status(404).json({ error: 'Course not found' });
        }
        const segments = course.gpxData;
        const curve = await (0, pacingService_1.generatePacingCurve)(segments, goalTimeSeconds);
        res.status(200).json({ success: true, curve });
    }
    catch (error) {
        console.error('Error generating pacing curve:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});
exports.default = router;
