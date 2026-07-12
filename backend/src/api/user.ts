import express from 'express';
import { requireAuth } from '../middleware/auth';
import prisma from '../services/db';

const router = express.Router();

router.get('/profile', requireAuth, async (req, res) => {
  try {
    const user = await prisma.paceflowUser.findUnique({
      where: { id: req.user.id }
    });
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      id: user.id,
      email: user.email,
      subscriptionTier: user.subscriptionTier,
      aiCredits: user.aiCredits
    });
  } catch (error) {
    console.error('Fetch Profile Error:', error);
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

export default router;
