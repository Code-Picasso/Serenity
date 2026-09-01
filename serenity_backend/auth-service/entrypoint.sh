#!/bin/sh
set -e

echo "Syncing auth database schema..."
npx prisma db push --skip-generate

echo "Starting auth service..."
exec node dist/index.js
