import { prisma } from '../db';

export async function runMonteCarloSimulation(userId: string, courseId: string, goalTimeSeconds: number) {
  const iterations = 10000;
  let successCount = 0;
  const finishTimes: number[] = [];

  for (let i = 0; i < iterations; i++) {
    // Normal distribution approximation using Box-Muller transform
    const u1 = Math.random();
    const u2 = Math.random();
    const z0 = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);
    
    // Baseline is goal time. We simulate variance (std dev = 5% of goal time)
    const stdDev = goalTimeSeconds * 0.05; 
    
    const simulatedFinishTime = Math.round(goalTimeSeconds + (z0 * stdDev));
    finishTimes.push(simulatedFinishTime);

    if (simulatedFinishTime <= goalTimeSeconds) {
      successCount++;
    }
  }

  // Calculate statistics
  const meanFinishTime = Math.round(finishTimes.reduce((a, b) => a + b, 0) / iterations);
  const successProbability = successCount / iterations;

  // Save the simulation record
  const simulation = await prisma.predictiveSimulation.create({
    data: {
      userId,
      courseId,
      scenarioParams: {
        iterations,
        meanFinishTime,
        successProbability
      },
      probableFinishTime: meanFinishTime,
      confidenceInterval: 0.95 // 95% CI is a placeholder
    }
  });

  return simulation;
}
