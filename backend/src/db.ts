import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

// Prisma client singleton
const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
  pool: Pool | undefined;
};

// Create PostgreSQL connection pool (singleton)
const pool = globalForPrisma.pool ?? new Pool({
  connectionString: Bun.env.DATABASE_URL,
});

if (Bun.env.NODE_ENV !== 'production') {
  globalForPrisma.pool = pool;
}

// Create Prisma adapter
const adapter = new PrismaPg(pool);

// Create Prisma client with adapter
export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    adapter,
    // Only log errors in all environments
    // Enable 'query' temporarily for debugging: ['query', 'error', 'warn']
    log: ['error', 'warn'],
  });

if (Bun.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
