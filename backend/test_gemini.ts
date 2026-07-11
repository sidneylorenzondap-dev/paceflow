import { prisma } from './src/db';

async function main() {
  const users = await prisma.paceflowUser.findMany();
  console.log('Users:', users.length);
}

main().catch(console.error).finally(() => prisma.$disconnect());
