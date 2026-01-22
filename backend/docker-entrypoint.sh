#!/bin/bash
set -e

# Default port for Railway
export PORT="${PORT:-8080}"

echo "=========================================="
echo "Druto Backend Startup"
echo "=========================================="
echo "Environment: ${NODE_ENV:-development}"
echo "Port: ${PORT}"
echo "=========================================="

# Debug: Check if DATABASE_URL is available
if [ -z "$DATABASE_URL" ]; then
  echo "❌ ERROR: DATABASE_URL is not set!"
  echo "Available env vars starting with 'DATA' or 'POST':"
  env | grep -E '^(DATA|POST)' || echo "(none found)"
  exit 1
else
  echo "✅ DATABASE_URL is set (length: ${#DATABASE_URL})"
fi

echo "Running database migrations..."
echo "Checking config file..."
echo "Root level files:"
ls -la *.ts 2>/dev/null || echo "No .ts files in root"
echo "Prisma folder:"
ls -la prisma/ | grep -E "(config|schema)"
if [ -f "prisma.config.ts" ]; then
  echo "✅ Config file found at root"
  cat prisma.config.ts
else
  echo "❌ Config file NOT found at root"
fi
bunx prisma migrate deploy

echo "Starting Bun server..."
exec bun src/index.ts
