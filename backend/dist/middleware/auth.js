"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAuth = void 0;
const supabase_js_1 = require("@supabase/supabase-js");
const db_1 = require("../db");
const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_ANON_KEY || '';
const supabase = (0, supabase_js_1.createClient)(supabaseUrl, supabaseKey);
const requireAuth = async (req, res, next) => {
    if (process.env.MOCK_MODE === 'true') {
        let user = await db_1.prisma.paceflowUser.findFirst();
        if (!user) {
            user = await db_1.prisma.paceflowUser.create({
                data: {
                    email: 'mock@example.com',
                    subscriptionTier: 'premium',
                    aiCredits: 10
                }
            });
        }
        req.user = user;
        return next();
    }
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    const token = authHeader.split(' ')[1];
    try {
        const { data: { user }, error } = await supabase.auth.getUser(token);
        if (error || !user) {
            return res.status(401).json({ error: 'Invalid token' });
        }
        let dbUser = await db_1.prisma.paceflowUser.findUnique({ where: { email: user.email || '' } });
        if (!dbUser) {
            dbUser = await db_1.prisma.paceflowUser.create({
                data: {
                    id: user.id,
                    email: user.email || '',
                    subscriptionTier: 'premium', // Default to premium for MVP
                    aiCredits: 20
                }
            });
        }
        req.user = dbUser;
        next();
    }
    catch (err) {
        return res.status(401).json({ error: 'Authentication failed' });
    }
};
exports.requireAuth = requireAuth;
