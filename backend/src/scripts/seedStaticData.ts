import { prisma } from '../db';

async function main() {
  console.log('Seeding static templates...');

  // 1. Static Recovery Templates
  await prisma.paceflowStaticRecovery.deleteMany({});
  
  await prisma.paceflowStaticRecovery.createMany({
    data: [
      {
        type: 'Easy Run',
        advice: {
          fatigueLevel: "Low",
          hydration: "Drink 500ml of water.",
          nutrition: "Normal balanced meal. No urgent carb loading required.",
          mobility: ["5 mins light walking", "Quad stretches", "Calf raises"],
          sleep: "Aim for 7-8 hours to maintain consistency.",
          nextRunReadiness: "You should be ready for another easy run or workout tomorrow."
        }
      },
      {
        type: 'Speedwork',
        advice: {
          fatigueLevel: "High",
          hydration: "Drink 750ml of water with electrolytes.",
          nutrition: "Consume 30-50g of carbs and 15g protein within 30 mins to replenish glycogen.",
          mobility: ["10 mins cool down jog", "Hamstring stretches", "Foam roll calves"],
          sleep: "Aim for 8+ hours. Your muscles need deep sleep to repair micro-tears from speed.",
          nextRunReadiness: "Keep it very easy tomorrow. Do not do two hard days back-to-back."
        }
      },
      {
        type: 'Long Run',
        advice: {
          fatigueLevel: "Very High",
          hydration: "Drink 1L of water with heavy electrolytes. Monitor urine color.",
          nutrition: "Heavy carb loading (60g+) and 20g protein immediately. Eat a large meal later.",
          mobility: ["Elevate legs against a wall for 10 mins", "Ice bath (optional)", "Light foam rolling"],
          sleep: "Prioritize 8-9 hours of sleep.",
          nextRunReadiness: "Take tomorrow completely off or do a 20 min active recovery walk/swim."
        }
      }
    ]
  });
  console.log('Static recovery templates seeded.');

  // 2. Static Training Plans
  await prisma.paceflowStaticPlan.deleteMany({});
  
  await prisma.paceflowStaticPlan.createMany({
    data: [
      {
        title: 'Beginner 5K Plan',
        distance: '5K',
        level: 'Beginner',
        planData: {
          goalAdjustmentNotice: null,
          adjustedTargetPace: null,
          workouts: [
            { day: "Monday", description: "Rest or 20 mins light walk.", type: "Rest", targetPaceMinKm: null, durationMins: 0 },
            { day: "Tuesday", description: "Easy jog with walking breaks. 1 min run, 1 min walk.", type: "Easy", targetPaceMinKm: 8.0, durationMins: 30 },
            { day: "Wednesday", description: "Rest or yoga.", type: "Rest", targetPaceMinKm: null, durationMins: 0 },
            { day: "Thursday", description: "Steady run. 2 mins run, 1 min walk.", type: "Moderate", targetPaceMinKm: 7.5, durationMins: 30 },
            { day: "Friday", description: "Rest day.", type: "Rest", targetPaceMinKm: null, durationMins: 0 },
            { day: "Saturday", description: "Long run (slow!). Just focus on time on feet.", type: "Long", targetPaceMinKm: 8.5, durationMins: 45 },
            { day: "Sunday", description: "Active recovery. Walk.", type: "Recovery", targetPaceMinKm: null, durationMins: 20 }
          ]
        }
      },
      {
        title: 'Sub-60 10K Plan',
        distance: '10K',
        level: 'Intermediate',
        planData: {
          goalAdjustmentNotice: null,
          adjustedTargetPace: null,
          workouts: [
            { day: "Monday", description: "Rest day.", type: "Rest", targetPaceMinKm: null, durationMins: 0 },
            { day: "Tuesday", description: "Intervals: 6 x 400m at 5:30/km pace.", type: "Speed", targetPaceMinKm: 5.5, durationMins: 40 },
            { day: "Wednesday", description: "Easy recovery run.", type: "Easy", targetPaceMinKm: 6.5, durationMins: 35 },
            { day: "Thursday", description: "Tempo run: 5km at 5:50/km pace.", type: "Tempo", targetPaceMinKm: 5.8, durationMins: 45 },
            { day: "Friday", description: "Rest or cross-train.", type: "Rest", targetPaceMinKm: null, durationMins: 0 },
            { day: "Saturday", description: "Long endurance run.", type: "Long", targetPaceMinKm: 6.5, durationMins: 75 },
            { day: "Sunday", description: "Active recovery.", type: "Recovery", targetPaceMinKm: null, durationMins: 20 }
          ]
        }
      }
    ]
  });
  console.log('Static training plans seeded.');
}

main()
  .catch((e) => {
    console.error(e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });