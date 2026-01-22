# Use official Bun image
FROM oven/bun:1 AS base
WORKDIR /app

# Install dependencies
FROM base AS deps
COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile

# Copy prisma config (root level) and schema, then generate client
COPY prisma.config.ts ./
COPY prisma ./prisma/
RUN bunx prisma generate

# Production image
FROM base AS runner
WORKDIR /app

# Copy node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy Prisma config and generated client from deps stage
COPY --from=deps /app/prisma.config.ts ./
COPY --from=deps /app/prisma ./prisma/

# Copy all source code
COPY . .

# Copy and setup entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port
EXPOSE 8080

# Use entrypoint script (runs migrations + starts server)
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
