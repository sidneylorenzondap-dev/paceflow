import { prisma } from '../src/db';
import * as dotenv from 'dotenv';
dotenv.config();

async function checkRuns() {
  const users = await prisma.paceflowUser.findMany();
  if (users.length === 0) {
    console.log("No users.");
    return;
  }
  console.log(`Found ${users.length} users.`);
  
  for (const user of users) {
    const runs = await prisma.paceflowRunSession.findMany({ where: { userId: user.id }});
    console.log(`User ${user.email} has ${runs.length} runs.`);
    for (const run of runs) {
      console.log(`  - Run: ${run.totalTime}s, avgPace: ${run.avgPace} min/km`);
      const dist = Math.round((run.totalTime / 60) / run.avgPace * 1000);
      console.log(`    Calculated dist: ${dist} m`);
    }
  }
}

checkRuns().catch(console.error).finally(() => prisma.$disconnect());
