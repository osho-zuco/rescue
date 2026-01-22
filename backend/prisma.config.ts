import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  // Conditional: only include datasource if DATABASE_URL exists (runtime)
  ...(process.env.DATABASE_URL && {
    datasource: {
      url: process.env.DATABASE_URL,
    },
  }),
});
