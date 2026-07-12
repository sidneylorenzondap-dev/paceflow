import { Request, Response, NextFunction } from 'express';
import { createClient } from '@supabase/supabase-js';
import { prisma } from '../db';

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_ANON_KEY || '';
const supabase = createClient(supabaseUrl, supabaseKey);

declare global {
  namespace Express {
    interface Request {
      user?: any;
    }
  }
}

export const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
  if (process.env.MOCK_MODE === 'true') {
    let user = await prisma.paceflowUser.findFirst();
    if (!user) {
      user = await prisma.paceflowUser.create({
        data: {
          email: 'mock@example.com',
          subscriptionTier: 'premium',
          aiCredits: 5
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
      console.error('[Auth Error] Invalid token:', error);
      return res.status(401).json({ error: 'Invalid token' });
    }

    let dbUser = await prisma.paceflowUser.findUnique({ where: { email: user.email || '' } });
    if (!dbUser) {
      dbUser = await prisma.paceflowUser.create({
        data: {
          id: user.id,
          email: user.email || '',
          subscriptionTier: 'premium', // Default to premium for MVP
          aiCredits: 5
        }
      });
    }

    req.user = dbUser;
    next();
  } catch (err) {
    console.error('[Auth Error] Authentication failed completely:', err);
    return res.status(401).json({ error: 'Authentication failed' });
  }
};
