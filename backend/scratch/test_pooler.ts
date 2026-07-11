import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://postgres.jjxwczjynvjvkgjcyiyo:X1fDgwKIcEm7jm1w@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
    }
  }
});

async function main() {
  console.log('Connecting...');
  const users = await prisma.paceflowUser.findMany();
  console.log('Users:', users.length);
}

main().catch(console.error).finally(() => prisma.$disconnect());
